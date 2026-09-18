require "net/http"
require "json"
require "uri"

module Yue2
  # Talks to a local ComfyUI running the YuE2 node pack.
  #
  # ComfyUI is a machine this application sends work to; it is never a source of
  # truth. Every method here is called from a background job, never from a
  # request, because a render takes minutes and the upstream server can be down
  # without the website noticing.
  #
  # Settings are tuned for the single 6 GB GPU this runs on: FP8 autoregressive
  # weights (Ada Lovelace supports them), AR-stage offload between stages, and
  # tiled decoding. Rendering one song at a time is enforced by the job's
  # concurrency limit, not by this client.
  class ComfyClient
    DEFAULT_URL = "http://127.0.0.1:8188"
    MODEL_ID = "m-a-p/YuE2-3B"
    VAE_ID = "m-a-p/YuE2-Vae"

    class Error < StandardError; end
    class Unreachable < Error; end
    class Rejected < Error; end
    class RenderTimeout < Error; end
    class MissingOutput < Error; end

    def initialize(base_url: ENV.fetch("COMFYUI_URL", DEFAULT_URL),
      timeout: ENV.fetch("COMFYUI_TIMEOUT", "7200").to_i,
      poll_interval: 2,
      memory_budget_gib: 6,
      precision: "fp8")
      @base_url = base_url.to_s.chomp("/")
      @timeout = timeout
      @poll_interval = poll_interval
      @memory_budget_gib = memory_budget_gib
      @precision = precision
    end

    # A cheap liveness probe. /system_stats is the smallest endpoint that proves
    # the server is up and can see a GPU.
    def healthy?
      body = JSON.parse(get("/system_stats"))
      body["devices"].present?
    rescue Error, JSON::ParserError
      false
    end

    # Queues one render and returns ComfyUI's prompt id.
    def queue!(style:, lyrics:, cot: "off", steps: 32, seed: nil)
      seed ||= SecureRandom.random_number(2**31)

      body = post("/prompt", { "prompt" => workflow(style: style, lyrics: lyrics, cot: cot, steps: steps, seed: seed),
                               "client_id" => client_id })

      body.fetch("prompt_id")
    rescue KeyError
      raise Rejected, "ComfyUI accepted the request but returned no prompt id"
    end

    # Blocks until the render finishes. This is the long wait: minutes for a
    # short song, potentially much longer on a small GPU.
    def wait_for(prompt_id)
      deadline = monotonic + timeout

      loop do
        entry = history_entry(prompt_id)

        return entry if entry&.dig("status", "completed")
        raise Rejected, error_message(entry) if entry && entry.dig("status", "status_str") == "error"
        raise RenderTimeout, "YuE2 render did not finish within #{timeout}s" if monotonic > deadline

        sleep poll_interval
      end
    end

    # The saved audio file recorded in a finished history entry.
    def audio_output(history_entry)
      (history_entry["outputs"] || {}).each_value do |node_output|
        files = node_output["audio"] || node_output["audio_files"]
        next unless files.is_a?(Array)

        match = files.find { |file| audio_file?(file) }
        return match if match
      end

      raise MissingOutput, "the render finished but produced no audio file"
    end

    def download(file_info)
      query = URI.encode_www_form(
        "filename" => file_info.fetch("filename"),
        "subfolder" => file_info["subfolder"].to_s,
        "type" => file_info["type"] || "output"
      )

      get_raw("/view?#{query}")
    end

    # The workflow in ComfyUI's API format: a hash of node id => class_type and
    # inputs, which is what POST /prompt expects. Node ids are stable strings so
    # this reads like the graph it is.
    def workflow(style:, lyrics:, cot:, steps:, seed:)
      {
        "1" => {
          "class_type" => "YuE2ModelLoader",
          "inputs" => {
            "source" => "hugging_face",
            "model" => MODEL_ID,
            "vae" => VAE_ID,
            "precision" => precision,
            "device" => "auto",
            "memory_budget_gib" => memory_budget_gib,
            "offload_ar" => true,
            "local_files_only" => false,
            "verify_hashes" => true,
            "revision" => "",
            "vae_revision" => "",
            "cache_dir" => ""
          }
        },
        "2" => {
          "class_type" => "YuE2PlanScore",
          "inputs" => {
            "runtime" => [ "1", 1 ],
            "style" => style.to_s,
            "lyrics" => lyrics.to_s,
            "cot" => cot,
            "seed" => seed,
            "cfg_scale" => -1,
            "abc" => "",
            "temperature" => 0.7,
            "top_p" => 0.9,
            "top_k" => 30,
            "repetition_penalty" => 1.005,
            "penalty_window" => 100,
            "min_tokens" => 32,
            "max_tokens" => 4096
          }
        },
        "3" => {
          "class_type" => "YuE2GenerateSemantic",
          "inputs" => {
            "runtime" => [ "1", 1 ],
            "plan" => [ "2", 0 ],
            "temperature" => 1.0,
            "top_p" => 0.95,
            "top_k" => 100,
            "repetition_penalty" => 1.2,
            "penalty_window" => 50,
            "min_tokens" => 32,
            "max_tokens" => 200
          }
        },
        "4" => {
          "class_type" => "YuE2EmptyLatent",
          "inputs" => { "conditioning" => [ "3", 0 ] }
        },
        "5" => {
          "class_type" => "RandomNoise",
          "inputs" => { "noise_seed" => seed }
        },
        "6" => {
          "class_type" => "BasicGuider",
          "inputs" => { "model" => [ "1", 0 ], "conditioning" => [ "3", 0 ] }
        },
        "7" => {
          "class_type" => "YuE2ExplicitMidpoint",
          "inputs" => {}
        },
        "8" => {
          "class_type" => "YuE2LinearSchedule",
          "inputs" => { "steps" => steps }
        },
        "9" => {
          "class_type" => "SamplerCustomAdvanced",
          "inputs" => {
            "noise" => [ "5", 0 ],
            "guider" => [ "6", 0 ],
            "sampler" => [ "7", 0 ],
            "sigmas" => [ "8", 0 ],
            "latent_image" => [ "4", 0 ]
          }
        },
        "10" => {
          "class_type" => "YuE2Decode",
          "inputs" => { "runtime" => [ "1", 1 ], "latent" => [ "9", 0 ], "full_decode" => false }
        },
        "11" => {
          "class_type" => "SaveAudioAdvanced",
          "inputs" => { "audio" => [ "10", 0 ], "filename_prefix" => "audio/apm", "format" => "flac" }
        }
      }
    end

    private

    attr_reader :base_url, :timeout, :poll_interval, :memory_budget_gib, :precision

    def client_id = @client_id ||= SecureRandom.uuid

    def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    def history_entry(prompt_id)
      JSON.parse(get("/history/#{prompt_id}"))[prompt_id]
    end

    def error_message(entry)
      messages = entry.dig("status", "messages") || []
      detail = messages.reverse.find { |(type, _)| type == "execution_error" }
      detail ? detail.last["exception_message"].to_s : "YuE2 render failed"
    end

    def audio_file?(file)
      file.is_a?(Hash) && file["filename"].to_s.match?(/\.(flac|wav|mp3|ogg)\z/i)
    end

    def connection
      @connection ||= begin
        uri = URI.parse(base_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 5
        http.read_timeout = 30
        http.write_timeout = 30
        http
      end
    end

    def get(path)
      response = request(Net::HTTP::Get.new(path))
      response.body
    end

    def get_raw(path)
      request(Net::HTTP::Get.new(path)).body
    end

    def post(path, payload)
      request = Net::HTTP::Post.new(path)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)
      JSON.parse(request(request).body)
    end

    def request(request)
      response = connection.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise Rejected, "ComfyUI returned #{response.code}: #{response.body.to_s.truncate(300)}"
      end

      response
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, SocketError, Net::OpenTimeout => e
      raise Unreachable, "ComfyUI at #{base_url} is unreachable (#{e.class})"
    rescue Net::ReadTimeout, Net::WriteTimeout
      # A per-request timeout is not a failed render: ComfyUI was busy moving
      # models. The caller's own deadline decides when to give up.
      raise Rejected, "ComfyUI did not respond in time to a single request"
    end
  end
end

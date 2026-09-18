# Stubs for the ComfyUI HTTP API, so job specs never touch a real renderer.
#
# The shapes mirror ComfyUI's: POST /prompt returns a prompt id, GET
# /history/{id} reports completion, GET /view returns bytes.
module ComfyStubs
  def stub_comfy_available(prompt_id: "prompt-123")
    stub_request(:post, %r{/prompt\z})
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
        body: { prompt_id: prompt_id, number: 1, node_errors: {} }.to_json)

    stub_request(:get, %r{/history/#{prompt_id}\z})
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
        body: {
          prompt_id => {
            "status" => { "status_str" => "success", "completed" => true },
            "outputs" => {
              "11" => { "audio" => [ { "filename" => "apm_00001.flac", "subfolder" => "audio", "type" => "output" } ] }
            }
          }
        }.to_json)

    stub_request(:get, %r{/view\?})
      .to_return(status: 200, headers: { "Content-Type" => "audio/flac" }, body: "FLACBYTES")
  end

  def stub_comfy_unreachable
    stub_request(:post, %r{/prompt\z}).to_raise(Errno::ECONNREFUSED)
  end

  def stub_comfy_failed(prompt_id: "prompt-123")
    stub_request(:post, %r{/prompt\z})
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
        body: { prompt_id: prompt_id }.to_json)

    stub_request(:get, %r{/history/#{prompt_id}\z})
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
        body: {
          prompt_id => {
            "status" => {
              "status_str" => "error",
              "completed" => false,
              "messages" => [ [ "execution_error", { "exception_message" => "CUDA out of memory" } ] ]
            },
            "outputs" => {}
          }
        }.to_json)
  end
end

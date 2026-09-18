module Catalogue
  # Synthesises a short preview tone for a seeded track.
  #
  # Why this exists: the catalogue's real audio comes from YuE2 renders, which
  # have not happened yet, but the preview player, the licence gate and the
  # audio-reactive front end all need something real to work against. This writes
  # an actual WAV - our own generated audio, no third-party material - from the
  # track's own key, tempo and mood.
  #
  # It is NOT a song and must never be presented as one. The UI labels any track
  # carrying one of these as a placeholder, and a generated master replaces it.
  class PreviewTone
    SAMPLE_RATE = 22_050
    SECONDS = 6.0

    # Semitone offsets from A4, for the note names the seeds use.
    NOTES = { "C" => -9, "C#" => -8, "D" => -7, "D#" => -6, "E" => -5, "F" => -4,
              "F#" => -3, "G" => -2, "G#" => -1, "A" => 0, "A#" => 1, "B" => 2 }.freeze

    MOOD_SHAPES = {
      "night drive" => [ 0, 7, 12 ], "optimistic" => [ 0, 4, 7 ], "urgent" => [ 0, 3, 7 ],
      "calm" => [ 0, 5, 12 ], "warm" => [ 0, 4, 9 ], "melancholic" => [ 0, 3, 8 ],
      "hopeful" => [ 0, 4, 7 ], "tense" => [ 0, 1, 7 ], "bright" => [ 0, 4, 9 ],
      "playful" => [ 0, 2, 7 ], "chaotic" => [ 0, 6, 11 ], "euphoric" => [ 0, 4, 11 ],
      "still" => [ 0, 7, 14 ], "vast" => [ 0, 5, 12 ]
    }.freeze

    def self.wav_for(track) = new(track).wav

    def initialize(track)
      @track = track
    end

    def wav
      samples = render
      header(samples.length) + samples.pack("s<*")
    end

    private

    attr_reader :track

    def root_hz
      name = track.musical_key.to_s[/\A[A-G]#?/] || "A"
      440.0 * (2.0**((NOTES.fetch(name, 0) - 12) / 12.0))
    end

    def chord
      MOOD_SHAPES.fetch(track.mood.to_s, [ 0, 4, 7 ])
    end

    def total_samples = (SAMPLE_RATE * SECONDS).to_i

    # A slow pad: three voices, a soft attack, a gentle tremolo, and a low-pass
    # tilt so it sits behind a voice rather than in front of it.
    def render
      voices = chord.map { |semitone| root_hz * (2.0**(semitone / 12.0)) }
      bpm = (track.bpm || 100).to_f
      tremolo_hz = (bpm / 60.0) / 4.0

      Array.new(total_samples) do |i|
        t = i.to_f / SAMPLE_RATE
        envelope = attack(t) * release(t)
        tremolo = 0.75 + 0.25 * Math.sin(2 * Math::PI * tremolo_hz * t)

        value = voices.each_with_index.sum do |hz, voice|
          # A touch of detune per voice keeps it from sounding like a test tone.
          detune = 1.0 + (voice - 1) * 0.0015
          Math.sin(2 * Math::PI * hz * detune * t) / (voice + 2.0)
        end

        (value * envelope * tremolo * 0.55 * 32_767).clamp(-32_767, 32_767).round
      end
    end

    def attack(t) = t < 0.6 ? t / 0.6 : 1.0

    def release(t)
      remaining = SECONDS - t
      remaining < 1.2 ? [ remaining / 1.2, 0 ].max : 1.0
    end

    # 16-bit mono PCM, which every browser plays and nothing here needs to decode.
    def header(sample_count)
      data_bytes = sample_count * 2

      [
        "RIFF", 36 + data_bytes, "WAVE",
        "fmt ", 16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16,
        "data", data_bytes
      ].pack("A4VA4A4VvvVVvvA4V")
    end
  end
end

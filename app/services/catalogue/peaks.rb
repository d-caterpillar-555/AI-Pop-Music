module Catalogue
  # The shape of a track's audio, captured once and stored.
  #
  # The visualiser could analyse audio in the browser, but then the drawing would
  # only exist while something was playing - and the piece is meant to show the
  # *song*, not the moment. These buckets are computed from the same generator
  # that writes the preview, so the picture and the sound are the same object.
  #
  # It reads PreviewTone's samples rather than the attached file. When a real
  # master replaces the placeholder the same class takes decoded PCM instead;
  # nothing else about the pipeline changes.
  class Peaks
    BUCKETS = 512

    def self.capture(track) = new(track).capture

    def initialize(track)
      @track = track
    end

    # Root mean square per bucket, not peak: a peak per bucket draws a spiky
    # silhouette that looks the same for a hi-hat and a bass note, whereas RMS
    # is loudness, which is what a waveform drawing is actually showing.
    def capture
      samples = Catalogue::PreviewTone.new(track).samples
      return [] if samples.empty?

      size = [ (samples.length.to_f / BUCKETS).ceil, 1 ].max

      values = (0...BUCKETS).map do |index|
        window = samples[index * size, size]
        next 0.0 if window.nil? || window.empty?

        sum = window.sum { |value| value.to_f**2 }
        Math.sqrt(sum / window.length) / 32_767.0
      end

      normalise(values)
    end

    private

    attr_reader :track

    # Scaled to the track's own loudest bucket, so a quiet track still draws a
    # full picture instead of a flat line near the floor.
    def normalise(values)
      ceiling = values.max
      return values if ceiling.nil? || ceiling.zero?

      values.map { |value| (value / ceiling).round(4) }
    end
  end
end

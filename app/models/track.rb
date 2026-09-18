# A catalogue record. Audio is licensed property, so a track that has ever been
# downloaded is never destroyed - it is discarded, or archived, and the license
# audit rows that reference it stay valid.
class Track < ApplicationRecord
  include Discard::Model

  # Exactly the audio types Marcel (and therefore active_storage_validations)
  # recognises. YuE2 produces FLAC; the rest are accepted so an editor can
  # replace a master without a code change. `audio/wav` is deliberately absent:
  # Marcel spells it `audio/vnd.wave` or `audio/x-wav`.
  AUDIO_CONTENT_TYPES = %w[
    audio/flac audio/x-flac audio/vnd.wave audio/x-wav
    audio/mpeg audio/ogg audio/opus audio/mp4 audio/aac
  ].freeze
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  belongs_to :genre
  has_many :track_downloads, dependent: :restrict_with_error

  has_one_attached :audio
  has_one_attached :preview
  has_one_attached :artwork

  enum :status, { draft: "draft", published: "published", archived: "archived" }, validate: true

  scope :published, -> { kept.where(status: "published") }
  scope :ordered, -> { order(:position, published_at: :desc) }

  validates :title, presence: true, length: { maximum: 140 }
  # A UX nicety; the unique index on slug is the actual guarantee (gems.md §14A).
  validates :slug, uniqueness: true, allow_blank: true
  validates :duration_ms, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :bpm, numericality: { only_integer: true, in: 20..400 }, allow_nil: true
  validates :lyrics, length: { maximum: 10_000 }, allow_nil: true
  validates :seed, numericality: { only_integer: true }, allow_nil: true

  validates :audio, content_type: { in: AUDIO_CONTENT_TYPES, message: "must be FLAC, WAV, MP3 or Ogg" },
    size: { less_than: 200.megabytes }, if: -> { audio.attached? }
  validates :preview, content_type: { in: AUDIO_CONTENT_TYPES, message: "must be FLAC, WAV, MP3 or Ogg" },
    size: { less_than: 20.megabytes }, if: -> { preview.attached? }
  validates :artwork, content_type: { in: IMAGE_CONTENT_TYPES, message: "must be a PNG, JPEG or WebP" },
    size: { less_than: 10.megabytes }, if: -> { artwork.attached? }

  before_validation :stamp_published_at

  def to_param = slug

  def duration_clock
    return nil unless duration_ms

    total = duration_ms / 1000
    format("%d:%02d", total / 60, total % 60)
  end

  # Human playback of the technical metadata, in the order a liner note would
  # list it. Blank values are omitted rather than shown as placeholders.
  def metadata_line
    [ genre&.name, bpm && "#{bpm} BPM", musical_key, duration_clock ].compact_blank.join(" · ")
  end

  def downloadable_now? = published? && downloadable? && !discarded?

  private

  def stamp_published_at
    self.published_at ||= Time.current if status == "published"
  end
end

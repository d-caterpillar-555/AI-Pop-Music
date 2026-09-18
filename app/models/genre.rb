class Genre < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :tracks, dependent: :restrict_with_error
  has_many :genre_entitlements, dependent: :restrict_with_error

  has_one_attached :artwork

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :name) }

  validates :name, presence: true, length: { maximum: 80 }
  # Uniqueness is guaranteed by the unique index on slug, which friendly_id
  # derives from the name and de-duplicates with a suffix. Two genres may share
  # a display name; they may not share a URL.
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :artwork,
    content_type: { in: %w[image/png image/jpeg image/webp], message: "must be a PNG, JPEG or WebP" },
    size: { less_than: 5.megabytes },
    if: -> { artwork.attached? }

  def to_param = slug

  def track_count = tracks.published.count
end

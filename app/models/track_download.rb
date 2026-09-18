# The license audit trail: which member took which master, under which license
# version, and when. Append-only at both layers (readonly in Ruby, trigger in
# Postgres) because it is the record that answers a licensing dispute.
class TrackDownload < ApplicationRecord
  belongs_to :user
  belongs_to :track

  validates :license_terms_version, presence: true

  scope :recent, -> { order(created_at: :desc) }

  before_update { raise ActiveRecord::ReadOnlyRecord, "track_downloads is append-only" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "track_downloads is append-only" }

  def readonly? = persisted?
end

class DataRequest < ApplicationRecord
  belongs_to :user

  enum :kind, { export: "export", deletion: "deletion" }, validate: true
  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    rejected: "rejected"
  }, validate: true

  validates :requested_at, presence: true
  validate :completed_has_timestamp

  scope :recent, -> { order(requested_at: :desc) }

  private

  def completed_has_timestamp
    return unless completed? && completed_at.blank?

    errors.add(:completed_at, "is required once a request is completed")
  end
end

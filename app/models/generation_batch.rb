# An admin's request to produce N tracks for one genre from one prompt. The runs
# are the individual render attempts; this is the intent, and the thing a human
# reviews afterwards.
class GenerationBatch < ApplicationRecord
  belongs_to :genre
  belongs_to :created_by, class_name: "User", optional: true

  has_many :generation_runs, dependent: :destroy

  enum :status, {
    draft: "draft",
    queued: "queued",
    running: "running",
    completed: "completed",
    canceled: "canceled"
  }, validate: true

  validates :name, presence: true, length: { maximum: 120 }
  validates :prompt_style, presence: true, length: { maximum: 2_000 }
  validates :cot, inclusion: { in: %w[off melody full] }
  validates :steps, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 256 }
  validates :requested_count, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }

  scope :recent, -> { order(created_at: :desc) }

  def succeeded_runs = generation_runs.where(status: "succeeded")

  def progress
    "#{succeeded_runs.count}/#{requested_count} generated"
  end

  def finished?
    generation_runs.where(status: %w[queued running]).none?
  end

  # Moves the batch through running -> completed as its runs progress. Called by
  # the job rather than by callbacks, so the batch's state always describes runs
  # that actually exist.
  def refresh_status!
    if generation_runs.pending.any?
      update!(status: "running") unless running?
    elsif succeeded_runs.any? || generation_runs.where(status: "failed").any?
      update!(status: "completed")
    end
  end
end

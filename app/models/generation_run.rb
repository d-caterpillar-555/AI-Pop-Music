# One attempt to render one song through ComfyUI. Failures are kept, with their
# error and timings: generation time is the main cost of this business, and a
# failed run is a real cost that must stay visible.
class GenerationRun < ApplicationRecord
  belongs_to :generation_batch
  belongs_to :track, optional: true

  enum :status, {
    queued: "queued",
    running: "running",
    succeeded: "succeeded",
    failed: "failed",
    canceled: "canceled"
  }, validate: true

  validates :error, presence: true, if: :failed?
  validates :duration_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :pending, -> { where(status: %w[queued running]) }
  scope :finished, -> { where(status: %w[succeeded failed canceled]) }

  def mark_running!(comfy_prompt_id:, at: Time.current)
    update!(status: "running", comfy_prompt_id: comfy_prompt_id, started_at: at)
  end

  def mark_succeeded!(track:, at: Time.current)
    update!(
      status: "succeeded",
      track: track,
      finished_at: at,
      duration_ms: started_at ? ((at - started_at) * 1000).round : nil,
      error: nil
    )
  end

  def mark_failed!(message, at: Time.current)
    update!(
      status: "failed",
      error: message.to_s.truncate(2_000),
      finished_at: at,
      duration_ms: started_at ? ((at - started_at) * 1000).round : nil
    )
  end
end

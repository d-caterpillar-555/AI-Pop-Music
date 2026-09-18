module Generation
  # Turns an approved batch into queued runs.
  #
  # Creating the runs inside the batch's row lock means two admins pressing
  # "queue" at the same moment cannot each create a full set. Enqueueing happens
  # after the transaction commits, because a job that runs before its row is
  # visible would fail on a missing record.
  class EnqueueBatch
    def self.call(...) = new(...).call

    def initialize(batch:)
      @batch = batch
    end

    def call
      return Result.failure(:no_style) if batch.prompt_style.blank?

      runs = []

      batch.with_lock do
        return Result.failure(:already_queued) if batch.queued? || batch.running?

        batch.update!(status: "queued")
        runs = Array.new(batch.requested_count) do
          batch.generation_runs.create!(status: "queued", seed: SecureRandom.random_number(2**31))
        end
      end

      runs.each { |run| GenerationRunJob.perform_later(run) }

      Result.success(runs)
    end

    private

    attr_reader :batch
  end
end

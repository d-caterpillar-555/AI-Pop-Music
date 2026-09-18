# Queues a batch's renders on the GPU queue.
#
# This is the admin's whole interaction with generation: write a prompt, set a
# count, press the action. The jobs serialise themselves, so pressing it twice
# or queueing several batches is safe - they run one at a time.
class Avo::Actions::QueueGenerationBatch < Avo::BaseAction
  self.name = "Queue generation"
  self.message = "Renders will be queued on the GPU queue and run one at a time."

  def handle(records: [], **)
    queued = 0
    failures = []

    records.each do |batch|
      result = Generation::EnqueueBatch.call(batch: batch)

      if result.success?
        queued += result.value.size
      else
        failures << "#{batch.name} (#{result.error.to_s.truncate(80)})"
      end
    end

    if failures.any?
      error "Queued #{queued} run(s). Skipped: #{failures.join('; ')}"
    else
      succeed "Queued #{queued} run(s). They will render one at a time."
    end
  end
end

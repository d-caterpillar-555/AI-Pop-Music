# Renders one song through YuE2 on the local ComfyUI and files the result as a
# draft track.
#
# Two rules shape this job:
#
# 1. One render at a time. `limits_concurrency` makes Solid Queue hold the job
#    until the GPU is free, so queueing fifty tracks cannot start fifty renders
#    on a 6 GB card.
# 2. Failures are kept. A failed run records its error and timings rather than
#    disappearing, because generation time is the real cost of this business.
class GenerationRunJob < ApplicationJob
  queue_as :gpu

  # Solid Queue semaphore: one concurrent run for this key, held for six hours
  # (longer than a render should ever take; a stuck render releases on process
  # death regardless).
  limits_concurrency to: 1, key: "yue2-gpu", duration: 6.hours

  # A ComfyUI that is not running yet is a normal condition on this machine:
  # retry rather than fail the run.
  retry_on Yue2::ComfyClient::Unreachable, wait: 5.minutes, attempts: 6
  discard_on ActiveRecord::RecordNotFound

  def perform(run)
    return unless run.queued?

    client = Yue2::ComfyClient.new
    batch = run.generation_batch

    prompt_id = client.queue!(
      style: batch.prompt_style,
      lyrics: batch.lyrics.to_s,
      cot: batch.cot,
      steps: batch.steps,
      seed: run.seed
    )

    run.mark_running!(comfy_prompt_id: prompt_id)
    batch.refresh_status!

    history = client.wait_for(prompt_id)
    audio = client.download(client.audio_output(history))

    track = file_track(run, audio)
    run.mark_succeeded!(track: track)
    batch.refresh_status!
  rescue Yue2::ComfyClient::Unreachable
    # Let retry_on schedule another attempt. The run stays queued on purpose:
    # nothing has been attempted yet.
    raise
  rescue Yue2::ComfyClient::Error => e
    run.mark_failed!(e.message)
    batch.refresh_status!
    Rails.logger.warn("GenerationRunJob: run #{run.id} failed: #{e.message}")
  end

  private

  def file_track(run, audio_bytes)
    batch = run.generation_batch

    track = Track.create!(
      genre: batch.genre,
      title: "Untitled - #{batch.genre.name} take #{run.id}",
      slug: "untitled-#{run.id}",
      status: "draft",
      lyrics: batch.lyrics,
      prompt_style: batch.prompt_style,
      model_id: Yue2::ComfyClient::MODEL_ID,
      seed: run.seed
    )

    track.audio.attach(
      io: StringIO.new(audio_bytes),
      filename: "apm-#{run.id}.flac",
      content_type: "audio/flac"
    )

    track
  end
end

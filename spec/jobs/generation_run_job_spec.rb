require "rails_helper"

RSpec.describe GenerationRunJob do
  let(:batch) { create(:generation_batch, requested_count: 1) }
  let(:run) { create(:generation_run, generation_batch: batch) }

  it "files a draft track from a successful render" do
    stub_comfy_available(prompt_id: "prompt-abc")

    described_class.perform_now(run)

    run.reload
    expect(run).to be_succeeded
    expect(run.comfy_prompt_id).to eq("prompt-abc")
    expect(run.track).to be_present

    track = run.track
    expect(track).to be_draft
    expect(track.genre).to eq(batch.genre)
    expect(track.prompt_style).to eq(batch.prompt_style)
    expect(track.model_id).to eq(Yue2::ComfyClient::MODEL_ID)
    expect(track.audio).to be_attached
  end

  it "keeps the failure and its message" do
    stub_comfy_failed(prompt_id: "prompt-bad")

    described_class.perform_now(run)

    run.reload
    expect(run).to be_failed
    expect(run.error).to include("CUDA out of memory")
    expect(run.track).to be_nil
  end

  it "leaves the run queued when ComfyUI is not reachable, so a retry can work" do
    stub_comfy_unreachable

    expect { described_class.perform_now(run) }.not_to raise_error

    expect(run.reload).to be_queued
    expect(run.error).to be_nil
  end

  it "does not re-render a run that has already finished" do
    run.update!(status: "succeeded")

    described_class.perform_now(run)

    expect(a_request(:post, %r{/prompt})).not_to have_been_made
  end

  it "moves the batch to completed when its runs finish" do
    stub_comfy_available(prompt_id: "prompt-xyz")

    described_class.perform_now(run)

    expect(batch.reload).to be_completed
  end
end

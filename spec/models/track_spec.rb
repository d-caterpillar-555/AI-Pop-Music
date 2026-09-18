require "rails_helper"

RSpec.describe Track do
  it "requires a title" do
    expect(build(:track, title: "")).not_to be_valid
  end

  it "enforces a unique slug" do
    create(:track, slug: "neon-rain")
    expect(build(:track, slug: "neon-rain")).not_to be_valid
  end

  describe "status constraints" do
    it "refuses a published track with no published_at, at the database level" do
      track = create(:track)

      expect {
        track.update_columns(status: "published", published_at: nil)
      }.to raise_error(ActiveRecord::StatementInvalid, /tracks_published_has_timestamp/)
    end

    it "stamps published_at when a track is published" do
      track = create(:track, :draft)
      expect(track.published_at).to be_nil

      track.update!(status: "published")

      expect(track.reload.published_at).to be_present
    end
  end

  describe "metadata sanity" do
    it "refuses an implausible bpm" do
      expect(build(:track, bpm: 1_000)).not_to be_valid
    end

    it "refuses a non-positive duration" do
      expect(build(:track, duration_ms: 0)).not_to be_valid
    end
  end

  describe "scopes" do
    it "publishes only published, kept tracks" do
      published = create(:track)
      create(:track, :draft)
      discarded = create(:track)
      discarded.discard

      expect(described_class.published).to contain_exactly(published)
    end
  end

  describe "#metadata_line" do
    it "joins the liner-note fields and omits blanks" do
      track = build(:track, genre: build(:genre, name: "Synthwave"), bpm: 110, musical_key: "F#m", duration_ms: 185_000)

      expect(track.metadata_line).to eq("Synthwave · 110 BPM · F#m · 3:05")
    end

    it "omits missing pieces rather than printing placeholders" do
      track = build(:track, genre: build(:genre, name: "Lo-fi"), bpm: nil, musical_key: nil, duration_ms: nil)

      expect(track.metadata_line).to eq("Lo-fi")
    end
  end
end

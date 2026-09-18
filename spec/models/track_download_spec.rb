require "rails_helper"

RSpec.describe TrackDownload do
  let(:user) { create(:user) }
  let(:track) { create(:track) }

  it "records the licence version it was granted under" do
    download = described_class.create!(user: user, track: track,
      license_terms_version: Rails.application.config.x.license_terms_version)

    expect(download.license_terms_version).to eq(Rails.application.config.x.license_terms_version)
  end

  it "requires a licence version" do
    expect(described_class.new(user: user, track: track, license_terms_version: "")).not_to be_valid
  end

  it "is append-only in Ruby" do
    download = described_class.create!(user: user, track: track, license_terms_version: "v1")

    expect { download.update!(license_terms_version: "tampered") }
      .to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { download.destroy! }
      .to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "is append-only in the database, so console access cannot rewrite it" do
    download = described_class.create!(user: user, track: track, license_terms_version: "v1")

    expect {
      described_class.connection.execute(
        "UPDATE track_downloads SET license_terms_version = 'tampered' WHERE id = #{download.id}"
      )
    }.to raise_error(ActiveRecord::StatementInvalid, /append-only/)
  end
end

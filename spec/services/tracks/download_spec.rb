require "rails_helper"

RSpec.describe Tracks::Download do
  let(:genre) { create(:genre) }
  let(:track) { create(:track, genre: genre) }

  def entitled_member
    user = create(:user)
    subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
    create(:genre_entitlement, subscription: subscription, genre: genre)
    user
  end

  it "records the download for an entitled member" do
    user = entitled_member

    result = described_class.call(user: user, track: track, ip: "203.0.113.7")

    expect(result).to be_success
    download = result.value
    expect(download.user).to eq(user)
    expect(download.license_terms_version).to eq(Rails.application.config.x.license_terms_version)
    expect(download.ip_hash).to be_present
    expect(download.ip_hash).not_to include("203.0.113.7")
  end

  it "refuses a member without an entitlement" do
    result = described_class.call(user: create(:user), track: track)

    expect(result).to be_failure
    expect(result.error).to eq(:not_entitled)
    expect(TrackDownload.count).to eq(0)
  end

  it "refuses a signed-out visitor" do
    result = described_class.call(user: nil, track: track)

    expect(result).to be_failure
    expect(TrackDownload.count).to eq(0)
  end
end

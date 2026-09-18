require "rails_helper"

RSpec.describe "Track downloads", type: :request do
  let(:genre) { create(:genre) }
  let(:track) { create(:track, genre: genre) }

  def attach_master(track)
    track.audio.attach(
      io: StringIO.new("fLaC\u0000\u0000\u0000\u0022binary-placeholder"),
      filename: "master.flac",
      content_type: "audio/flac"
    )
  end

  it "refuses a signed-out visitor and records nothing" do
    post track_downloads_path(track)

    expect(response).to redirect_to(new_user_session_path)
    expect(TrackDownload.count).to eq(0)
  end

  it "refuses a member with no entitlement, and writes no licence record" do
    sign_in_as create(:user)

    post track_downloads_path(track)

    expect(response).to redirect_to(track_path(track))
    follow_redirect!
    expect(response.body).to include("not included in your subscription")
    expect(TrackDownload.count).to eq(0)
  end

  it "serves the master and records the licence for an entitled member" do
    user = create(:user)
    subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
    create(:genre_entitlement, subscription: subscription, genre: genre)
    attach_master(track)
    sign_in_as(user)

    post track_downloads_path(track)

    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("#{track.slug}.flac")

    download = TrackDownload.last
    expect(download.user).to eq(user)
    expect(download.track).to eq(track)
    expect(download.license_terms_version).to eq(Rails.application.config.x.license_terms_version)

    event = AuditEvent.find_by(action: "track.downloaded")
    expect(event.user).to eq(user)
  end

  it "refuses to record a licence when the master has not been attached yet" do
    user = create(:user)
    subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
    create(:genre_entitlement, subscription: subscription, genre: genre)
    sign_in_as(user)

    post track_downloads_path(track)

    expect(response).to redirect_to(track_path(track))
    follow_redirect!
    expect(response.body).to include("not available yet")
    expect(TrackDownload.count).to eq(0)
  end
end

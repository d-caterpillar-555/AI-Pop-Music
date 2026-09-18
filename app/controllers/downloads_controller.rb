class DownloadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_track

  # A member who is signed in but not entitled gets told why, on the track page,
  # instead of a generic refusal. Signed-out visitors are handled by
  # authenticate_user! before this can fire.
  rescue_from Pundit::NotAuthorizedError, with: :not_entitled

  def create
    authorize @track, :download?

    # Check the file exists BEFORE recording anything. A licence record for a
    # download that never delivered a file would be a false audit entry.
    unless @track.audio.attached?
      return redirect_to track_path(@track), alert: "The master for this track is not available yet."
    end

    result = Tracks::Download.call(user: current_user, track: @track, ip: client_ip)

    if result.failure?
      return redirect_to track_path(@track), alert: "That track is not included in your subscription."
    end

    AuditEvent.record!(action: "track.downloaded", user: current_user, subject: @track, ip: client_ip,
      metadata: { license_terms_version: result.value.license_terms_version })

    # The bytes are read through Rails rather than handed to a public storage
    # URL, so the licence check and the file cannot come apart. A catalogue of
    # masters this size fits in memory; a streaming proxy is the scale path.
    blob = @track.audio.blob
    send_data blob.download,
      filename: download_filename(@track, blob),
      type: blob.content_type,
      disposition: "attachment"
  end

  private

  def set_track
    @track = Track.kept.find_by!(slug: params[:slug])
  end

  def not_entitled
    redirect_to track_path(@track), alert: "That track is not included in your subscription."
  end

  def download_filename(track, blob)
    extension = File.extname(blob.filename.to_s)
    "#{track.slug}#{extension}"
  end
end

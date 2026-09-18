class TracksController < ApplicationController
  before_action :set_track

  def show
    authorize @track, :show?

    @entitled = current_member&.can_download?(@track) || false
  end

  # The public audio. Served through Rails rather than a storage URL so the file
  # never has a permanent public address, and cached briefly because a genre page
  # can start several previews.
  def preview
    authorize @track, :preview?

    unless @track.preview.attached?
      return redirect_to track_path(@track), alert: "No preview is available for this track yet."
    end

    expires_in 10.minutes, public: true
    blob = @track.preview.blob
    send_data blob.download, filename: blob.filename.to_s, type: blob.content_type, disposition: "inline"
  end

  private

  def set_track
    @track = Track.kept.find_by!(slug: params[:slug])
  end
end

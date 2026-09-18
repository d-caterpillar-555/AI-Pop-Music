module Account
  class DownloadsController < BaseController
    def index
      authorize TrackDownload, :index?

      @downloads = member.track_downloads.includes(track: :genre).recent
    end
  end
end

module Tracks
  # Records the act of a member taking a master, and is the only path that
  # yields the file. Two responsibilities, deliberately together: a download
  # that is not recorded must not happen, and a record without a download is
  # noise.
  class Download
    def self.call(...) = new(...).call

    def initialize(user:, track:, ip: nil)
      @user = user
      @track = track
      @ip = ip
    end

    def call
      return Result.failure(:not_entitled) unless user&.can_download?(track)

      download = TrackDownload.create!(
        user: user,
        track: track,
        license_terms_version: Rails.application.config.x.license_terms_version,
        ip_hash: AuditEvent.hash_ip(ip)
      )

      Result.success(download)
    rescue ActiveRecord::RecordNotUnique
      Result.failure(:duplicate)
    end

    private

    attr_reader :user, :track, :ip
  end
end

module Account
  class DashboardController < BaseController
    def show
      authorize member, :show?

      @subscription = member.live_subscription
      @plan = @subscription&.plan
      @entitlements = @subscription ? @subscription.genre_entitlements.includes(:genre) : []
      @recent_downloads = member.track_downloads.includes(track: :genre).recent.limit(5)
      @pending_order = member.orders.awaiting_payment.recent.first
    end
  end
end

module Subscriptions
  # Cancels a subscription but does not delete anything: the entitlements are
  # removed so access stops at once, while the billing history stays readable.
  class Cancel
    def self.call(...) = new(...).call

    def initialize(subscription:, at: Time.current, reason: nil)
      @subscription = subscription
      @at = at
      @reason = reason
    end

    def call
      subscription.with_lock do
        subscription.genre_entitlements.destroy_all

        subscription.update!(
          status: "canceled",
          canceled_at: at,
          current_period_end: [ subscription.current_period_end, at ].compact.max
        )

        subscription.record_event!("canceled", { reason: reason }.compact)
      end

      Result.success(subscription)
    end

    private

    attr_reader :subscription, :at, :reason
  end
end

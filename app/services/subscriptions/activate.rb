module Subscriptions
  # Moves a subscription to active and opens its billing period.
  #
  # In v1 nothing calls this from a webhook path, because there is no gateway:
  # an admin marks an order paid, which calls this. When a provider is added,
  # its webhook calls the same method - that is the whole point of keeping the
  # transition in one place.
  class Activate
    def self.call(...) = new(...).call

    def initialize(subscription:, order: nil, at: Time.current)
      @subscription = subscription
      @order = order
      @at = at
    end

    def call
      subscription.with_lock do
        was_active = subscription.active?

        subscription.update!(
          status: "active",
          current_period_start: at,
          current_period_end: at + interval_length,
          canceled_at: nil
        )

        subscription.record_event!(
          was_active ? "renewed" : "activated",
          { order_id: order&.id, plan_slug: subscription.plan.slug, period_end: subscription.current_period_end.iso8601 }
        )
      end

      Result.success(subscription)
    end

    private

    attr_reader :subscription, :order, :at

    def interval_length = subscription.plan.per_month? ? 1.month : 1.year
  end
end

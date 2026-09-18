require "rails_helper"

RSpec.describe Order do
  describe "identifiers" do
    it "generates a human number and an opaque public token" do
      order = create(:order)

      expect(order.number).to match(/\AAPM-\d{6}-[0-9A-F]{8}\z/)
      expect(order.public_token.length).to be >= 24
    end

    it "refuses a short public token at the database level" do
      order = create(:order)

      expect {
        order.update_column(:public_token, "short")
      }.to raise_error(ActiveRecord::StatementInvalid, /orders_public_token_long_enough/)
    end
  end

  describe "amount" do
    it "defaults to the plan price" do
      plan = create(:plan, price_cents: 1500)
      expect(create(:order, plan: plan).amount_cents).to eq(1500)
    end

    it "refuses a zero amount at the database level" do
      order = create(:order)

      expect {
        order.update_column(:amount_cents, 0)
      }.to raise_error(ActiveRecord::StatementInvalid, /orders_amount_positive/)
    end
  end

  describe "#mark_paid!" do
    it "records the payment and activates the subscription" do
      user = create(:user)
      plan = create(:plan, genre_limit: 2)
      order = create(:order, user: user, plan: plan)

      order.mark_paid!

      expect(order.reload).to be_paid
      expect(order.paid_at).to be_present

      subscription = user.reload.live_subscription
      expect(subscription).to be_active
      expect(subscription.current_period_end).to be > Time.current
      expect(subscription.subscription_events.map(&:kind)).to include("activated")
    end

    it "cannot represent a paid order without a payment time" do
      order = create(:order)

      expect {
        order.update_columns(status: "paid", paid_at: nil)
      }.to raise_error(ActiveRecord::StatementInvalid, /orders_paid_has_timestamp/)
    end
  end
end

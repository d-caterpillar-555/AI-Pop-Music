require "rails_helper"

RSpec.describe Subscriptions::AddGenre do
  let(:plan) { create(:plan, genre_limit: 2) }
  let(:subscription) { create(:subscription, :active, plan: plan) }

  it "grants access to a genre" do
    genre = create(:genre)

    result = described_class.call(subscription: subscription, genre: genre)

    expect(result).to be_success
    expect(subscription.entitled?(genre)).to be(true)
  end

  it "records a subscription event" do
    genre = create(:genre)

    described_class.call(subscription: subscription, genre: genre)

    expect(subscription.subscription_events.map(&:kind)).to include("genre_added")
  end

  it "refuses a genre that would exceed the plan limit" do
    create_list(:genre_entitlement, 2, subscription: subscription)
    extra = create(:genre)

    result = described_class.call(subscription: subscription, genre: extra)

    expect(result).to be_failure
    expect(result.error).to eq(:genre_limit_reached)
    expect(subscription.entitled?(extra)).to be(false)
  end

  it "refuses a genre already on the subscription" do
    genre = create(:genre)
    described_class.call(subscription: subscription, genre: genre)

    result = described_class.call(subscription: subscription, genre: genre)

    expect(result.error).to eq(:already_entitled)
    expect(subscription.genre_entitlements.count).to eq(1)
  end

  it "refuses to overfill when the same slot is taken twice concurrently" do
    # Two threads, one free slot, real row locking. Without the lock both would
    # read "1 of 2 used" and both would insert.
    create_list(:genre_entitlement, 1, subscription: subscription)
    first, second = create_list(:genre, 2)

    results = [ first, second ].map do |genre|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(subscription: Subscription.find(subscription.id), genre: genre)
        end
      end
    end.map(&:value)

    expect(results.count(&:success?)).to eq(1)
    expect(subscription.reload.genre_entitlements.count).to eq(2)
  end
end

class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  # Entitlements are working state and may be recreated; events are the audit
  # record and may never be deleted (the DB trigger refuses).
  has_many :genre_entitlements, dependent: :destroy
  has_many :subscription_events, dependent: :restrict_with_error
  has_many :genres, through: :genre_entitlements
  has_many :orders, through: :user

  enum :status, {
    incomplete: "incomplete",
    active: "active",
    past_due: "past_due",
    canceled: "canceled"
  }, validate: true

  scope :live, -> { where(status: %w[incomplete active past_due]) }
  scope :current, -> { where(status: %w[active past_due]) }

  def entitled?(genre)
    return false unless genre

    genre_entitlements.exists?(genre_id: genre.id)
  end

  def at_genre_limit?
    genre_entitlements.count >= plan.genre_limit
  end

  def remaining_genre_slots
    [ plan.genre_limit - genre_entitlements.count, 0 ].max
  end

  # A subscription that exists but cannot yet grant downloads because the order
  # behind it is still awaiting payment.
  def awaiting_activation?
    incomplete? && user.orders.awaiting_payment.exists?
  end

  def record_event!(kind, payload = {})
    subscription_events.create!(kind: kind, occurred_at: Time.current, payload: payload)
  end
end

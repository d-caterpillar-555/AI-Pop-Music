class Order < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  enum :status, {
    awaiting_payment: "awaiting_payment",
    paid: "paid",
    refunded: "refunded",
    canceled: "canceled"
  }, validate: true

  before_validation :assign_identifiers, on: :create

  validates :number, presence: true, uniqueness: true
  validates :public_token, presence: true, uniqueness: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :placed_at, presence: true

  scope :recent, -> { order(placed_at: :desc) }

  def to_param = public_token

  # In v1 nothing calls this automatically: there is no gateway. An admin marks
  # an order paid once the money has arrived out of band, which is the plug
  # point a provider webhook will occupy later.
  def mark_paid!(at: Time.current)
    transaction do
      update!(status: "paid", paid_at: at)
      subscription = user.live_subscription || user.subscriptions.create!(plan: plan, status: "incomplete")
      Subscriptions::Activate.call(subscription: subscription, order: self)
    end
  end

  private

  def assign_identifiers
    self.number ||= generate_number
    self.public_token ||= SecureRandom.urlsafe_base64(24)
    self.placed_at ||= Time.current
    self.amount_cents ||= plan&.price_cents
    self.currency ||= plan&.currency || "USD"
  end

  def generate_number
    "APM-#{Time.current.strftime('%Y%m')}-#{SecureRandom.hex(4).upcase}"
  end
end

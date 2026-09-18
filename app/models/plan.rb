class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :price_cents) }

  validates :name, presence: true, length: { maximum: 60 }
  validates :price_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :genre_limit, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :interval, inclusion: { in: %w[month year] }

  def to_param = slug

  def price = BigDecimal(price_cents) / 100

  def formatted_price
    format("%s%.2f", currency == "USD" ? "$" : "#{currency} ", price)
  end

  def per_month? = interval == "month"

  def billed_as = per_month? ? "per month" : "per year"
end

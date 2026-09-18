class NewsletterSubscriber < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def confirmed? = confirmed_at.present?

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end
end

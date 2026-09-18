class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :validatable, :trackable

  # The DB CHECK constraint is the guarantee; validate: true is the friendly
  # error message. `admin` implies nothing automatically - every action is
  # still authorised through a Pundit policy.
  enum :role, { member: "member", editor: "editor", admin: "admin" }, validate: true

  # Records are never deleted while licensing history exists: the audit tables
  # (subscription_events, track_downloads) are append-only by trigger. Account
  # deletion therefore anonymises instead of destroying - see #anonymize!.
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :track_downloads, dependent: :restrict_with_error
  has_many :data_requests, dependent: :destroy
  has_many :genre_entitlements, through: :subscriptions
  has_many :generation_batches, foreign_key: :created_by_id,
    dependent: :nullify, inverse_of: :created_by

  validates :name, presence: true, length: { maximum: 120 }
  # Registering means accepting the terms; the timestamp is the auditable fact,
  # not a boolean.
  validates :terms_accepted_at, presence: true, on: :create

  scope :admins, -> { where(role: "admin") }

  def self.anonymised_email(id) = "deleted+#{id}@ai-pop-music.invalid"

  # The subscription that currently grants access, if any.
  def live_subscription
    subscriptions.live.order(created_at: :desc).first
  end

  def subscribed?
    live_subscription&.active? || live_subscription&.past_due? || false
  end

  def entitled_genre_ids
    return [] unless live_subscription

    live_subscription.genre_entitlements.pluck(:genre_id)
  end

  def entitled_to?(genre)
    return false unless genre

    entitled_genre_ids.include?(genre.id)
  end

  def can_download?(track)
    return false unless track&.downloadable? && track.published?

    subscribed? && entitled_to?(track.genre)
  end

  # Erases personal data while preserving the commercial record. Required for a
  # deletion request to be answerable at all: the audit tables are append-only.
  def anonymize!
    transaction do
      update!(
        email: self.class.anonymised_email(id),
        name: "Deleted member",
        current_sign_in_ip: nil,
        last_sign_in_ip: nil,
        remember_created_at: nil
      )
      update_columns(encrypted_password: "", reset_password_token: nil, updated_at: Time.current)
    end
  end
end

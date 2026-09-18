# Append-only consent history. A subject's current consent is the newest row for
# a kind; the rows themselves are never edited or deleted (DB trigger).
class ConsentRecord < ApplicationRecord
  KINDS = %w[analytics marketing cookies terms].freeze

  validates :subject_token, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :policy_version, presence: true
  validates :granted_at, presence: true
  validate :revocation_after_grant

  before_update { raise ActiveRecord::ReadOnlyRecord, "consent_records is append-only" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "consent_records is append-only" }

  def readonly? = persisted?

  scope :for_subject, ->(token) { where(subject_token: token) }
  scope :recent_first, -> { order(granted_at: :desc) }

  # The current state for a subject and kind: granted, or granted-then-revoked.
  def self.current_for(subject_token, kind: nil)
    scope = for_subject(subject_token)
    scope = scope.where(kind: kind) if kind
    scope.recent_first.first
  end

  def self.granted?(subject_token, kind:)
    record = current_for(subject_token, kind: kind)
    record.present? && record.revoked_at.nil?
  end

  def revoked? = revoked_at.present?

  private

  def revocation_after_grant
    return if revoked_at.blank? || granted_at.blank?

    errors.add(:revoked_at, "cannot precede the grant") if revoked_at < granted_at
  end
end

class AuditEvent < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # IPs are stored only as a keyed hash: enough to correlate abuse, useless as
  # personal data if the table leaks.
  def self.hash_ip(ip)
    return nil if ip.blank?

    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, ip.to_s)
  end

  def self.record!(action:, user: nil, subject: nil, ip: nil, metadata: {})
    create!(
      action: action,
      user: user,
      subject_type: subject&.class&.name,
      subject_id: subject&.id,
      ip_hash: hash_ip(ip),
      metadata: metadata
    )
  end
end

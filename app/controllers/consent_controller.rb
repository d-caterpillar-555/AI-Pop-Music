class ConsentController < ApplicationController
  # Consent is recorded against an opaque subject token, so an anonymous
  # visitor's choice can be honoured without an account.
  def create
    authorize ConsentRecord, :create?

    ConsentRecord.create!(
      subject_token: subject_token,
      kind: consent_kind,
      granted_at: Time.current,
      revoked_at: (params[:granted] == "false" ? Time.current : nil),
      policy_version: Rails.application.config.x.license_terms_version
    )

    AuditEvent.record!(action: "consent.recorded", user: current_member, ip: client_ip,
      metadata: { kind: consent_kind, granted: params[:granted] != "false" })

    head :no_content
  end

  private

  def consent_kind
    kind = params[:kind].to_s
    ConsentRecord::KINDS.include?(kind) ? kind : "cookies"
  end

  def subject_token
    cookies.signed[:consent_subject] ||= SecureRandom.urlsafe_base64(16)
  end
end

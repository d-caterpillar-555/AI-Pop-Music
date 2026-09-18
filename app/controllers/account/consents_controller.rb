module Account
  class ConsentsController < BaseController
    def show
      authorize ConsentRecord, :show?

      @consents = ConsentRecord.for_subject(consent_token).recent_first
      @current = ConsentRecord::KINDS.index_with { |kind| ConsentRecord.granted?(consent_token, kind: kind) }
    end

    def update
      authorize ConsentRecord, :create?

      kind = params[:kind].to_s
      granted = params[:granted] == "true"

      if ConsentRecord::KINDS.exclude?(kind)
        return redirect_to account_consent_path, alert: "That consent type is not recognised."
      end

      ConsentRecord.create!(
        subject_token: consent_token,
        kind: kind,
        granted_at: Time.current,
        revoked_at: (granted ? nil : Time.current),
        policy_version: Rails.application.config.x.license_terms_version
      )

      redirect_to account_consent_path, notice: "Your choice was recorded."
    end

    private

    def consent_token = "user:#{member.id}"
  end
end

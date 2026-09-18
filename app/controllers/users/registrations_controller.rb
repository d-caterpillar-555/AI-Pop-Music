module Users
  class RegistrationsController < Devise::RegistrationsController
    rate_limit to: 5, within: 10.minutes, only: :create,
      with: -> { redirect_to new_user_registration_path, alert: "Too many attempts. Try again shortly." }

    # Editing an account lives at /account/profile, where the member also sees
    # their subscription and downloads. Devise's own edit screen would be a
    # second, thinner copy of the same thing.
    def edit
      redirect_to account_profile_path
    end

    protected

    def sign_up_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def account_update_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
    end

    # Accepting the terms is part of registering, and the timestamp is recorded
    # rather than a boolean: "when did they agree" is the auditable fact.
    def build_resource(hash = {})
      super
      self.resource.terms_accepted_at = Time.current if params.dig(:user, :terms_accepted).present?
    end
  end
end

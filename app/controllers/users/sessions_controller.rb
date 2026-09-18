module Users
  class SessionsController < Devise::SessionsController
    # Native Rails 8 throttling, backed by the configured cache store. An
    # account-takeover attempt costs something even when the attacker never
    # touches the database.
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to new_user_session_path, alert: "Too many sign-in attempts. Try again in a few minutes." }

    def new
      super
    end

    def create
      super
    end

    def destroy
      super
    end
  end
end

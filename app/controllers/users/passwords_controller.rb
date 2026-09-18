module Users
  class PasswordsController < Devise::PasswordsController
    rate_limit to: 5, within: 15.minutes, only: :create,
      with: -> { redirect_to new_user_password_path, alert: "Too many reset requests. Try again later." }
  end
end

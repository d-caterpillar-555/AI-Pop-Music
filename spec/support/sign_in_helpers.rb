# Request and system specs reach real controllers, so they sign in for real
# rather than stubbing warden.
module SignInHelpers
  def sign_in_as(user, password: "password1234")
    post user_session_path, params: { user: { email: user.email, password: password } }
  end
end

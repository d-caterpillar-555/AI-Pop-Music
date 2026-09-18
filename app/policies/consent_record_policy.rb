# Consent is recorded against an opaque subject token, so a visitor who has not
# signed in can still give or withdraw it. There is nothing to escalate: the
# record only ever concerns the token the request itself carries.
class ConsentRecordPolicy < ApplicationPolicy
  def create? = true
  def show? = signed_in?
end

class UserPolicy < ApplicationPolicy
  # The account area acts on the signed-in member's own record, which is the
  # record the controller passes in. `owner?` in the base class looks for a
  # user_id column, which a User does not have, so membership is compared here.
  def show? = own_account? || admin?
  def update? = own_account? || admin?
  def edit? = update?

  private

  def own_account? = signed_in? && record.id == user.id
end

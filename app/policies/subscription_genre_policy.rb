# Authorises actions on the subscription from the nested genre routes, where
# the record is the subscription the genres are being added to.
class SubscriptionGenrePolicy < ApplicationPolicy
  def create? = manages_subscription?
  def destroy? = manages_subscription?

  private

  def manages_subscription?
    return true if admin?
    return false unless signed_in?

    user.live_subscription&.id == record.id
  end
end

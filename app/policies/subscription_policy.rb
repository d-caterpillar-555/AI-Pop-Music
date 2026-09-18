class SubscriptionPolicy < ApplicationPolicy
  # Reading your own subscription, including its entitlements and history.
  def show? = owner? || admin?

  # Starting a subscription is the one action a signed-in member performs here;
  # the plan is chosen by the route, not by the body, so there is nothing to
  # escalate.
  def new? = signed_in?
  def create? = signed_in?

  def destroy? = owner? || admin?
end

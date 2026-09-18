class OrderPolicy < ApplicationPolicy
  # An order is reached by presenting its opaque public token, which the
  # controller uses to find the record. Possession of that token is the
  # authorisation, so this returns true for anyone holding the record - what
  # must never happen is an order being findable by sequential id, and the
  # route and the lookup both forbid that.
  def show? = true

  def index? = signed_in?

  # Only an admin marks an order paid (or, later, a verified provider webhook).
  def update? = admin?
end

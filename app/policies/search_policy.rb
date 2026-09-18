class SearchPolicy < ApplicationPolicy
  # Search returns published catalogue records only; the scope enforces that.
  def show? = true
end

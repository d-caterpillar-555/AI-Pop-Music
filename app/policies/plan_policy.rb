class PlanPolicy < ApplicationPolicy
  # Pricing is public: hiding the price is a dark pattern the design system bans.
  def index? = true

  def show? = record.active? || editor?

  class Scope < ApplicationPolicy::Scope
    def resolve
      editor? ? scope.all : scope.active
    end
  end
end

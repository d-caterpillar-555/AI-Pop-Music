class PostPolicy < ApplicationPolicy
  def index? = true

  def show? = record.published? || editor?

  class Scope < ApplicationPolicy::Scope
    def resolve
      editor? ? scope.all : scope.published
    end
  end
end

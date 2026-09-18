class GenrePolicy < ApplicationPolicy
  # The catalogue is public by design: browsing and previewing is how a visitor
  # decides to subscribe.
  def index? = true

  # An unpublished genre is invisible until an editor is working on it.
  def show? = record.published? || editor?

  # Editors see drafts; everyone else sees only what is published.
  class Scope < ApplicationPolicy::Scope
    def resolve
      editor? ? scope.all : scope.published
    end
  end
end

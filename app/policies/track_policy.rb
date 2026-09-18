class TrackPolicy < ApplicationPolicy
  def index? = true

  # Unpublished tracks are drafts for editors, not catalogue entries.
  def show? = (record.published? && !record.discarded?) || editor?

  # Previews are the public audio. The master is not.
  def preview? = show?

  # The entitlement check is the whole point: signed in is not enough, the
  # member must hold a live subscription that covers this track's genre.
  def download? = user.present? && user.can_download?(record)

  class Scope < ApplicationPolicy::Scope
    # A visitor browsing the catalogue never sees drafts or discarded tracks.
    def resolve
      editor? ? scope.all : scope.published
    end
  end
end

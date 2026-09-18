class PagePolicy < ApplicationPolicy
  def index? = true

  # Legal and informational pages are public once published.
  def show? = record.published? || editor?
end

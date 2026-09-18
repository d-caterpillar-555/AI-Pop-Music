class TrackDownloadPolicy < ApplicationPolicy
  # A member sees their own download history; an admin sees anyone's.
  def index? = signed_in?
  def show? = owner? || admin?
end

class DataRequestPolicy < ApplicationPolicy
  def index? = signed_in?
  def new? = signed_in?
  def create? = signed_in?

  def show? = owner? || admin?
end

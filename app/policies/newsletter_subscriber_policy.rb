class NewsletterSubscriberPolicy < ApplicationPolicy
  def create? = true
  def index? = admin?
end

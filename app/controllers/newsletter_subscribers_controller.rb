class NewsletterSubscribersController < ApplicationController
  def create
    authorize NewsletterSubscriber, :create?

    subscriber = NewsletterSubscriber.find_or_initialize_by(email: params.dig(:newsletter_subscriber, :email))

    if subscriber.persisted?
      redirect_back fallback_location: root_path, notice: "You are already on the list."
    elsif subscriber.save
      redirect_back fallback_location: root_path, notice: "Check your inbox to confirm your subscription."
    else
      redirect_back fallback_location: root_path, alert: subscriber.errors.full_messages.to_sentence
    end
  end
end

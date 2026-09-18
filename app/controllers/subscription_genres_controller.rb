class SubscriptionGenresController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription
  before_action :set_genre, only: [ :create, :destroy ]

  def create
    authorize @subscription, policy_class: SubscriptionGenrePolicy

    result = Subscriptions::AddGenre.call(subscription: @subscription, genre: @genre)

    if result.success?
      redirect_to subscription_path, notice: "#{@genre.name} added to your subscription."
    else
      redirect_to subscription_path, alert: alert_for(result.error)
    end
  end

  def destroy
    authorize @subscription, policy_class: SubscriptionGenrePolicy

    result = Subscriptions::RemoveGenre.call(subscription: @subscription, genre: @genre)

    if result.success?
      redirect_to subscription_path, notice: "#{@genre.name} removed."
    else
      redirect_to subscription_path, alert: "That genre is not on your subscription."
    end
  end

  private

  def set_subscription
    @subscription = current_user.live_subscription
    return if @subscription

    redirect_to plans_path, alert: "Start a subscription before choosing genres."
  end

  def set_genre
    # The slug travels as `genre_slug` on both create and destroy, so the
    # destroy route's :id segment is only ever the slug - never a database id
    # that a caller could enumerate.
    slug = params[:genre_slug].presence || params[:id]
    @genre = Genre.published.find_by!(slug: slug)
  end

  def alert_for(error)
    case error
    when :genre_limit_reached
      "Your plan covers #{@subscription.plan.genre_limit} " \
        "#{"genre".pluralize(@subscription.plan.genre_limit)}. Remove one to add another."
    when :already_entitled
      "#{@genre.name} is already on your subscription."
    else
      "That genre could not be added."
    end
  end
end

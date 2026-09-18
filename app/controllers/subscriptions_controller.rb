class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: []
  before_action :set_subscription, only: [ :show, :destroy ]

  # Starting a subscription. With no payment gateway in v1 this creates the
  # commercial record - a subscription and an order awaiting payment - and hands
  # the member an order page with instructions. Marking the order paid is an
  # admin action; when a provider is added, its webhook calls the same service.
  def new
    @plan = Plan.active.find_by!(slug: params[:plan_slug])
    @subscription = current_user.live_subscription
    authorize @subscription || Subscription, :new?

    @order = nil
  end

  def create
    @plan = Plan.active.find_by!(slug: params[:plan_slug])
    authorize Subscription, :create?

    subscription = current_user.live_subscription
    order = nil

    ActiveRecord::Base.transaction do
      if subscription.nil?
        subscription = current_user.subscriptions.create!(plan: @plan, status: "incomplete")
        subscription.record_event!("created", { plan_slug: @plan.slug })
      elsif subscription.plan_id != @plan.id
        previous = subscription.plan
        subscription.update!(plan: @plan)
        subscription.record_event!("plan_changed", { from: previous.slug, to: @plan.slug })
      end

      order = current_user.orders.create!(plan: @plan)
    end

    redirect_to order_path(order),
      notice: "Your subscription request is recorded. Complete payment to activate it."
  end

  def show
    authorize @subscription

    @plan = @subscription.plan
    @entitlements = @subscription.genre_entitlements.includes(:genre).order("genres.name")
    @available_genres = Genre.published.ordered.where.not(id: @entitlements.map(&:genre_id))
    @pending_order = current_user.orders.awaiting_payment.recent.first
  end

  def destroy
    authorize @subscription

    Subscriptions::Cancel.call(subscription: @subscription)
    AuditEvent.record!(action: "subscription.canceled", user: current_user, subject: @subscription, ip: client_ip)

    redirect_to account_root_path, notice: "Your subscription is canceled. Your download history is unaffected."
  end

  private

  def set_subscription
    @subscription = current_user.live_subscription || current_user.subscriptions.order(created_at: :desc).first
    return if @subscription

    redirect_to plans_path, alert: "You do not have a subscription yet." and return
  end
end

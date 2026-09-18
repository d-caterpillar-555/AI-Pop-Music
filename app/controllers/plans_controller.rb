class PlansController < ApplicationController
  def index
    authorize Plan, :index?

    @plans = policy_scope(Plan).active.ordered.includes(:subscriptions)
  end

  def show
    @plan = Plan.find_by!(slug: params[:slug])
    authorize @plan
  end
end

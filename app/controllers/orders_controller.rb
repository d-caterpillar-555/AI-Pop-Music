class OrdersController < ApplicationController
  # A guest reaches their order by opaque token, never by id.
  def show
    @order = Order.includes(:plan, :user).find_by!(public_token: params[:public_token])
    authorize @order

    @subscription = @order.user.subscriptions.order(created_at: :desc).first
  end
end

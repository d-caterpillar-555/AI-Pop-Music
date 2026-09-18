module Account
  class OrdersController < BaseController
    def index
      authorize Order, :index?

      @orders = member.orders.includes(:plan).recent
    end

    def show
      @order = member.orders.includes(:plan).find_by!(number: params[:number])
      authorize @order
    end
  end
end

module Account
  class DataRequestsController < BaseController
    def index
      authorize DataRequest, :index?

      @data_requests = member.data_requests.recent
    end

    def new
      authorize DataRequest, :new?

      @data_request = member.data_requests.new
    end

    def create
      authorize DataRequest, :create?

      @data_request = member.data_requests.new(
        kind: params.dig(:data_request, :kind),
        requested_at: Time.current
      )

      if @data_request.save
        AuditEvent.record!(action: "data_request.created", user: member, subject: @data_request, ip: client_ip)
        redirect_to account_data_requests_path,
          notice: "Your request is logged. Requests are actioned within 30 days."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end
end

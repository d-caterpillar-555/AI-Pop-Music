class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Authorisation is not opt-in here. A controller action that forgets to
  # authorize fails loudly in development and test instead of quietly serving
  # data it should not.
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  helper_method :current_member

  private

  def current_member = user_signed_in? ? current_user : nil

  def not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not allowed to do that." }
      format.any { head :forbidden }
    end
  end

  # The request IP is only ever persisted as a keyed hash (AuditEvent.hash_ip).
  def client_ip = request.remote_ip
end

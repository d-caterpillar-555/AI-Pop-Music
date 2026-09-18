# Default deny. Every policy starts closed and opens only the actions it means
# to, so a new controller action is unauthorised until someone says otherwise.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  def signed_in? = !user.nil?

  def admin? = !!user&.admin?

  # Editors prepare the catalogue; they do not touch commercial records.
  def editor? = admin? || !!user&.editor?

  def owner? = signed_in? && record.respond_to?(:user_id) && record.user_id == user.id

  # Scopes are where a policy decides which rows an actor may see at all. The
  # base class refuses to guess: a policy that supports listing says how.
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} must implement #resolve"
    end

    private

    attr_reader :user, :scope

    def admin? = !!user&.admin?

    def editor? = admin? || !!user&.editor?
  end
end

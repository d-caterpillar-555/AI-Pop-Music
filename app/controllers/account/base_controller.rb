module Account
  # Every account screen belongs to the signed-in member. Scoping starts here
  # rather than in each action, so a new screen cannot accidentally query the
  # whole table.
  class BaseController < ApplicationController
    before_action :authenticate_user!

    private

    def member = current_user
    helper_method :member
  end
end

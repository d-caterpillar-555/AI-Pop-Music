module Users
  # Devise screens are about the session, not about a stored record, so they sit
  # outside ApplicationController. That keeps `verify_authorized` meaningful on
  # the controllers that do hold records, instead of being switched off
  # everywhere to accommodate sign-in.
  class BaseController < ActionController::Base
    allow_browser versions: :modern
    stale_when_importmap_changes
  end
end

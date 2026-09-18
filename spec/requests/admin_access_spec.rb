require "rails_helper"

# The admin panel is the highest-value target in the application: it can read
# every customer, order and licence. These specs exist so that ungating it is a
# failing test rather than a discovery.
RSpec.describe "Admin access", type: :request do
  it "refuses a signed-out visitor" do
    get "/admin"

    expect(response).to redirect_to(new_user_session_path)
  end

  it "refuses a signed-in member" do
    sign_in_as create(:user)

    get "/admin"

    expect(response).to redirect_to("/")
  end

  it "refuses a member the resource routes too, not just the dashboard" do
    sign_in_as create(:user)

    get "/admin/resources/tracks"

    expect(response).to redirect_to("/")
  end

  it "allows an editor" do
    sign_in_as create(:user, :editor)

    get "/admin"
    follow_redirect! if response.redirect?

    expect(response).to have_http_status(:ok)
  end

  it "allows an admin" do
    sign_in_as create(:user, :admin)

    get "/admin"
    follow_redirect! if response.redirect?

    expect(response).to have_http_status(:ok)
  end

  it "lets an admin reach a resource index" do
    sign_in_as create(:user, :admin)

    get "/admin/resources/tracks"

    expect(response).to have_http_status(:ok)
  end
end

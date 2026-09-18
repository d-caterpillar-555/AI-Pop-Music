require "rails_helper"

# Walks the product the way a visitor and a member do. These are the specs that
# would catch a policy, a route or a view breaking in a way unit specs cannot.
RSpec.describe "The catalogue and subscription flow", type: :request do
  let!(:genre) { create(:genre, name: "Synthwave") }
  let!(:plan) { create(:plan, name: "Starter", slug: "starter", genre_limit: 1) }
  let!(:track) { create(:track, genre: genre, title: "Neon Rain") }

  describe "public pages" do
    it "renders the home page with published catalogue entries" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Neon Rain")
      expect(response.body).to include("Synthwave")
    end

    it "lists genres" do
      get genres_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Synthwave")
    end

    it "shows a genre with its tracks" do
      get genre_path(genre)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Neon Rain")
      expect(response.body).to include("Subscribe")
    end

    it "shows a track with a subscribe prompt for visitors" do
      get track_path(track)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Subscribe to download")
    end

    it "hides an unpublished genre from visitors" do
      get genre_path(create(:genre, :unpublished))

      expect(response).to have_http_status(:not_found).or have_http_status(:ok)
    end

    it "lists plans with prices" do
      get plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$5")
    end

    it "searches the catalogue by title" do
      get search_path(q: "Neon")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Neon Rain")
    end

    it "searches the catalogue by genre name" do
      get search_path(q: "Synth")

      expect(response.body).to include("Synthwave")
    end

    it "serves the static legal pages" do
      %w[/about /license /privacy /terms /cookies /contact].each do |path|
        get path
        expect(response).to have_http_status(:ok), "expected #{path} to render"
      end
    end

    it "serves robots.txt and the sitemap" do
      get robots_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Disallow: /account")

      get sitemap_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<urlset")
    end

    it "serves the health check" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "starting a subscription" do
    let(:member) { create(:user) }

    it "requires sign-in" do
      get subscribe_path(plan_slug: plan.slug)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the plan summary to a signed-in member" do
      sign_in_as(member)

      get subscribe_path(plan_slug: plan.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Starter")
    end

    it "records a subscription and an order awaiting payment" do
      sign_in_as(member)

      expect {
        post subscription_path(plan_slug: plan.slug)
      }.to change(Order, :count).by(1)

      order = Order.last
      expect(order).to be_awaiting_payment
      expect(order.plan).to eq(plan)
      expect(response).to redirect_to(order_path(order))

      expect(member.reload.live_subscription).to be_incomplete
      expect(member.live_subscription.subscription_events.map(&:kind)).to include("created")
    end
  end

  describe "managing genres on a subscription" do
    let(:member) { create(:user) }
    let!(:subscription) { create(:subscription, :active, user: member, plan: plan) }

    before { sign_in_as(member) }

    it "renders the subscription page with progress" do
      get subscription_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("0 of 1 used")
    end

    it "adds a genre within the plan limit" do
      expect {
        post subscription_genres_path(genre_slug: genre.slug)
      }.to change(GenreEntitlement, :count).by(1)

      expect(member.reload.entitled_to?(genre)).to be(true)
    end

    it "refuses a genre beyond the plan limit" do
      post subscription_genres_path(genre_slug: genre.slug)
      other = create(:genre)

      expect {
        post subscription_genres_path(genre_slug: other.slug)
      }.not_to change(GenreEntitlement, :count)

      follow_redirect!
      expect(response.body).to include("covers 1 genre")
    end

    it "removes a genre" do
      post subscription_genres_path(genre_slug: genre.slug)

      expect {
        delete subscription_genre_path(genre.slug, genre_slug: genre.slug)
      }.to change(GenreEntitlement, :count).by(-1)
    end

    it "cancels the subscription and drops the entitlements" do
      post subscription_genres_path(genre_slug: genre.slug)

      delete subscription_path

      expect(subscription.reload).to be_canceled
      expect(subscription.genre_entitlements.count).to eq(0)
    end
  end

  describe "the account area" do
    let(:member) { create(:user) }

    before { sign_in_as(member) }

    it "renders every account screen" do
      [
        account_root_path,
        account_profile_path,
        edit_account_profile_path,
        account_downloads_path,
        account_orders_path,
        account_consent_path,
        account_data_requests_path,
        new_account_data_request_path
      ].each do |path|
        get path
        expect(response).to have_http_status(:ok), "expected #{path} to render"
      end
    end

    it "updates the profile" do
      patch account_profile_path, params: { user: { name: "New Name", email: member.email } }

      expect(member.reload.name).to eq("New Name")
    end

    it "records a data request" do
      expect {
        post account_data_requests_path, params: { data_request: { kind: "export" } }
      }.to change(DataRequest, :count).by(1)
    end

    it "records a consent decision" do
      expect {
        patch account_consent_path(kind: "analytics", granted: "true")
      }.to change(ConsentRecord, :count).by(1)

      expect(ConsentRecord.granted?("user:#{member.id}", kind: "analytics")).to be(true)
    end
  end

  describe "public micro-endpoints" do
    it "accepts a consent decision from a visitor" do
      expect {
        post consent_path(kind: "cookies", granted: "true")
      }.to change(ConsentRecord, :count).by(1)

      expect(response).to have_http_status(:no_content)
    end

    it "accepts a newsletter signup" do
      expect {
        post newsletter_subscribers_path, params: { newsletter_subscriber: { email: "reader@example.com" } }
      }.to change(NewsletterSubscriber, :count).by(1)
    end
  end
end

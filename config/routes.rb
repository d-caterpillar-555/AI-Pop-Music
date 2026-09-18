Rails.application.routes.draw do
  mount_avo

  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  # --- Catalogue ------------------------------------------------------------
  get "/genres", to: "genres#index", as: :genres
  get "/genres/:slug", to: "genres#show", as: :genre
  get "/tracks/:slug", to: "tracks#show", as: :track
  get "/tracks/:slug/preview", to: "tracks#preview", as: :track_preview
  get "/search", to: "searches#show", as: :search

  # State changes are resources, not custom GETs, per the routing convention in
  # skills.md.
  post "/tracks/:slug/downloads", to: "downloads#create", as: :track_downloads

  # --- Plans and subscription ------------------------------------------------
  get "/plans", to: "plans#index", as: :plans
  get "/plans/:slug", to: "plans#show", as: :plan

  get "/subscribe/:plan_slug", to: "subscriptions#new", as: :subscribe
  resource :subscription, only: [ :show, :create, :destroy ] do
    resources :genres, only: [ :create, :destroy ], controller: "subscription_genres"
  end

  # Guests reach their order by opaque token, never by sequential id.
  get "/orders/:public_token", to: "orders#show", as: :order

  # --- Accounts --------------------------------------------------------------
  devise_for :users,
    path: "account",
    controllers: { registrations: "users/registrations", passwords: "users/passwords" },
    skip: [ :sessions ]

  # Devise's session routes are redefined so sign-in can be rate limited
  # alongside the other authentication endpoints.
  devise_scope :user do
    get "/account/sign_in", to: "users/sessions#new", as: :new_user_session
    post "/account/sign_in", to: "users/sessions#create", as: :user_session
    delete "/account/sign_out", to: "users/sessions#destroy", as: :destroy_user_session
  end

  namespace :account do
    root "dashboard#show"
    resource :profile, only: [ :show, :edit, :update ]
    resources :downloads, only: [ :index ]
    resources :orders, only: [ :index, :show ], param: :number
    resource :consent, only: [ :show, :update ]
    resources :data_requests, only: [ :index, :new, :create ]
  end

  # --- Content ---------------------------------------------------------------
  get "/blog", to: "posts#index", as: :blog
  get "/blog/:slug", to: "posts#show", as: :blog_post

  # --- Consent and newsletter ------------------------------------------------
  resource :consent, only: [ :create ], controller: "consent"
  resources :newsletter_subscribers, only: [ :create ]

  # --- Machine-readable ------------------------------------------------------
  get "/sitemap.xml", to: "sitemaps#show", as: :sitemap, defaults: { format: "xml" }
  get "/robots.txt", to: "robots#show", as: :robots, defaults: { format: "text" }

  # --- Static pages ----------------------------------------------------------
  # An explicit allowlist rather than a catch-all, so an unknown path is a
  # genuine 404 rather than a database lookup on every request.
  #
  # A local variable, not a constant: routes reload, and a constant would warn
  # about reinitialisation on every reload.
  page_slugs = %w[
    about license contact privacy terms cookies
  ]

  page_slugs.each do |slug|
    get "/#{slug}", to: "pages#show", defaults: { slug: slug }, as: :"page_#{slug.tr('-', '_')}"
  end
end

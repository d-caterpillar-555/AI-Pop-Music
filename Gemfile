source "https://rubygems.org"

gem "rails", "~> 8.1.3", ">= 8.1.3.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false
gem "thruster", require: false

# Pinned to 2.x. The json 3.0 release changed JSON.parse's signature and Rails
# 8.1.3.1's ActiveRecord::Type::Json#deserialize still calls it the old way, so
# reading ANY jsonb column raises ArgumentError. Bundler resolves json 3.0.2 by
# default because nothing else constrains it. Remove this pin once Rails
# declares support for json 3.
gem "json", "~> 2.7"

gem "image_processing", "~> 1.2"
# Loaded lazily: image_processing only needs the Vips constant when a variant is
# actually processed. Requiring it at boot would make the whole application
# depend on a system libvips being present just to start.
gem "ruby-vips", "~> 2.3", require: false

# Authentication and authorisation
gem "devise", "~> 5.0"
gem "pundit", "~> 2.5"

# Admin
gem "avo", "~> 4.2"

# Search
gem "meilisearch-rails", "~> 0.16.0"

# Pagination and public URLs
gem "pagy", "~> 43.6"
gem "friendly_id", "~> 5.7"

# Forms
gem "simple_form", "~> 5.4"

# Uploads
gem "active_storage_validations", "~> 4.1"

# Email
gem "resend", "~> 1.15"

# Monitoring and audit
gem "sentry-rails", "~> 7.0"
gem "paper_trail", "~> 17.0"

# Soft deletion
gem "discard", "~> 2.0"

# Migration safety
gem "strong_migrations", "~> 2.8"

# Security scanning
gem "brakeman", require: false
gem "bundler-audit", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.5"

  gem "rubocop", "~> 1.90", require: false
  gem "rubocop-rails-omakase", require: false

  gem "annotate"
  gem "letter_opener"
end

group :development do
  gem "web-console"
  gem "bullet", "~> 8.2"
  gem "pry-rails"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 8.0"
  gem "simplecov", "~> 1.3", require: false
  gem "vcr"
  gem "webmock"
  gem "test-prof"
end

gem "dotenv-rails", "~> 3.2", groups: [ :development, :test ]

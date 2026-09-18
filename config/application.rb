require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AiPopMusic
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # The database carries things schema.rb cannot express: append-only triggers
    # on the audit tables and CHECK constraints the tests assert against. Dumping
    # SQL instead of Ruby is what makes the test database match production
    # behaviour rather than merely resembling it.
    config.active_record.schema_format = :sql

    # Catalogue timestamps are stored and displayed in UTC; the UI formats them
    # in the viewer's zone.
    config.time_zone = "UTC"

    # The license version recorded on every download. Bump it when the terms in
    # app/views/pages/license change, so a download can always be traced to the
    # terms that were in force when it happened.
    config.x.license_terms_version = ENV.fetch("LICENSE_TERMS_VERSION", "2026-09-18")

    # Every generated file gets a spec, and factories are not generated for
    # models that should not have them (none yet - this is the default posture).
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  end
end

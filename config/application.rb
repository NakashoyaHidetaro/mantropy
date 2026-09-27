require_relative 'boot'

require 'rails'

# 使用しているフレームワークだけを読み込む(Action Cable / Action Mailbox /
# Action Text はこのアプリでは未使用のため読み込まない)。
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mantropy
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 8.1
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
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :ja
    config.i18n.available_locales = %i[ja en]
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

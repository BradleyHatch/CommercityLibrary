# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'c'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.paths['db/migrate'] = config.paths['db/migrate'].expanded

    Rails.application.config.active_job.queue_adapter = :sucker_punch
  end
end

# frozen_string_literal: true

module C
  class Engine < ::Rails::Engine
    isolate_namespace C

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end

    initializer :append_migrations do |app|
      config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << expanded_path
      end
    end

    config.to_prepare do
      Dir.glob(Rails.root + 'app/decorators/**/*_decorator*.rb').each do |c|
        require_dependency(c)
      end
    end

    initializer 'my_engine.action_controller' do
      ActiveSupport.on_load :action_controller do
        helper C::PresenterHelper unless self == ActionController::API
      end
    end

    ActionView::Base.field_error_proc = proc do |html_tag, _instance|
      class_attr_index = html_tag.index 'class="'
      if class_attr_index
        html_tag.insert class_attr_index + 7, 'error'
      else
        html_tag.insert html_tag.index('>'), ' class="error"'
      end
    end

    # Date
    Date::DATE_FORMATS[:default] = '%d/%m/%Y'

    # Time
    Time::DATE_FORMATS[:default] = '%H:%M - %d/%m/%Y'

    initializer 'my_engine.middleware' do |app|
      app.config.middleware.use ExceptionNotification::Rack,
                                email: {
                                  email_prefix: "[#{C.store_name} ERROR] ",
                                  sender_address: %("notifier" <notifier@#{C.domain_name}>),
                                  exception_recipients: C.errors_email
                                }
    end
  end
end

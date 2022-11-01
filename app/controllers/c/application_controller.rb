# frozen_string_literal: true

module C
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception, prepend: true
    before_action :author=
    before_action :redirect_if_no_site
    layout :layout

    def layout
      devise_controller? ? 'c/commercity_login_layout' : 'c/application'
    end

    def current_ability
      @current_ability ||= ::C::Ability.new(current_user)
    end

    private

    def author=
      C::ApplicationRecord.author = current_user
    end

    def redirect_if_no_site
      if C.no_site
        unless devise_controller?
          unless request.path.split('/').second == 'admin'
            redirect_to '/admin'
          end
        end
      end
    end
  end
end

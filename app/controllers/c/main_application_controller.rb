# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  class MainApplicationController < ApplicationController
    layout 'c/main_application'
    helper C::CartsHelper
    helper C::StorefrontHelper
    helper C::WishlistHelper
    helper C::PagesHelper
    include C::PagesHelper
    before_action :use_pretty_id!

    before_action do
      # set search object
      @q = C::Product::Variant.ransack(params[:q])
    end

    before_action :check_redirects
    before_action :store_current_location, unless: :devise_controller?

    def use_pretty_id!
      ApplicationRecord.use_pretty_id!
    end

    private

    def check_redirects
      return unless (redirect = C::Redirect.find_by(old_url: request.path))
      redirect.increment
      redirect_to URI.parse(redirect.new_url).path
    end

    def store_current_location
      store_location_for(:front_customer_account, request.url)
    end

    def assign_page_info(object)
      @_page_info = object
    end
  end
end

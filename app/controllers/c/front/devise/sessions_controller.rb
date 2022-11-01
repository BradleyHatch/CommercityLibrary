# frozen_string_literal: true
# rubocop:disable all
module C
  class Front::Devise::SessionsController < Devise::SessionsController
    layout 'c/main_application'
    after_action :after_login, only: :create


    before_action do
      @q ||= C::Product::Variant.ransack(params[:q])
    end

    def after_login
      return unless session[:cart_id].present?
      current_front_customer_account.customer.assign_cart(session[:cart_id])
    end

    def after_sign_in_path_for(resource)
      request[:checkout] ? new_checkout_path : super
    end

    def after_sign_out_path_for(_resource_or_scope)
      '/'
    end
  end
end

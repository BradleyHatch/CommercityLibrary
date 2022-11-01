# frozen_string_literal: true
# rubocop:disable all
module C
  class Front::Devise::RegistrationsController < Devise::RegistrationsController
    layout 'c/main_application'

    before_action do
      @q ||= C::Product::Variant.ransack(params[:q])
    end

    def after_sign_up_path_for(resource)
      if session[:cart_id].present?
        current_front_customer_account.customer.assign_cart(session[:cart_id])
        session.delete(:cart_id)
      end
      params['checkout'] ? new_checkout_path : super
    end

    private

    def after_sign_out_path_for(resource)
      '/'
    end

    private

    def sign_up_params
      h = params.require(:front_customer_account).permit(
        :email, :password, :password_confirmation,
        customer_attributes: [:name]
      )
      h[:customer_attributes][:email] = h[:email]
      h
    end
  end
end

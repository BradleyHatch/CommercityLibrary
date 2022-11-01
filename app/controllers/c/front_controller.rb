# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  class FrontController < MainApplicationController
    before_action :authenticate_front_customer_account!

    before_action do
      @q ||= C::Product::Variant.ransack(params[:q])
    end

  end
end

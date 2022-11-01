# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Front
    class OrdersController < MainApplicationController
      def show
        @order = C::Order::Sale.find_by(access_token: params[:access_token])
      end

      def index
        @orders = current_front_customer_account.customer.orders
      end
    end
  end
end

# frozen_string_literal: true

module C
  module PaymentMethod
    class ProForma < ApplicationRecord
      include Payable

      def finalize!(user_params = {})
        order.customer.is_trade?
      end

      def paid?
        true
      end
    end
  end
end

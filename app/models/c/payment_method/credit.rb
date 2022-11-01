# frozen_string_literal: true

module C
  module PaymentMethod
    class Credit < ApplicationRecord
      include Payable

      def finalize!(user_params = {})
        order.customer.account.credit?
      end

      def paid?
        true
      end
    end
  end
end

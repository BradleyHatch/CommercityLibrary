# frozen_string_literal: true

module C
  module PaymentMethod
    class Manual < ApplicationRecord
      include Payable

      def paid?
        true
      end

      def finalize!(user_params = {})
        true
      end
    end
  end
end

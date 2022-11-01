# frozen_string_literal: true

module C
  module PaymentMethod
    class WorldpayBusinessGateway < ApplicationRecord
      include Payable

      # Do nothing. Everything has been done in lib and the controller.
      def finalize!(user_params = {})
        true
      end

      # If we start storing failed transactions, this will not make much sense,
      # so take care.
      def paid?
        transaction_id.present?
      end
    end
  end
end

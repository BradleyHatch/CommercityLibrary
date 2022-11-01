# frozen_string_literal: true

# Payment Sense does everything in one go and with lib classes, so don't worry
# about finalizing. By the time the finalize! method is called, the payment has
# already gone through. Investigating PREAUTH transactions may be a good idea.

module C
  module PaymentMethod
    class PaymentSense < ApplicationRecord
      include Payable

      # Do nothing. Everything has been done in lib and the controller.
      def finalize!(user_params = {})
        true
      end

      # If we start storing failed transactions, this will not make much sense,
      # so take care.
      def paid?
        cross_reference.present?
      end
    end
  end
end

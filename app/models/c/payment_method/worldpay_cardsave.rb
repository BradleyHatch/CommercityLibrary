# frozen_string_literal: true

# Worldpay Cardsave does everything in one go and with lib classes, so don't
# worry about finalizing. By the time the finalize! method is called, the
# payment has already gone through.
#
# Investigating PREAUTH transactions may be a good idea, as that may allow us
# to bring the confirmation button back to Commercity, as with Paypal Express.

module C
  module PaymentMethod
    class WorldpayCardsave < ApplicationRecord
      include Payable

      # Do nothing. Everything has been done in lib and the controller.
      def finalize!(user_params = {})
        true
      end

      ##
      # Cross reference is only set when Worldpay sends a return to us that was
      # both valid and successful. See PaymentMethods#worldpay_cardsave_return
      # and WorldpayCardsave::Response for when the response is valid and
      # successful.
      #
      # If we start storing failed transactions, this will not make much sense,
      # so take care.
      def paid?
        cross_reference.present?
      end
    end
  end
end

# frozen_string_literal: true

require_dependency 'c/application_controller'
require 'deko'

module C
  module FrontEnd
    class DekoController < MainApplicationController
      skip_before_action :verify_authenticity_token

      ##
      # When receiving a Credit Status Notification from Deko, find the order
      # and decide based on the status in the notification what to do with it.
      def csn_return
        csn = Deko::CreditStatusNotification.new(request.request_parameters)
        payment = C::PaymentMethod::DekoFinance.find_by(
          unique_reference: csn.unique_reference
        )
        payment.deko_id ||= csn.deko_id
        payment.csn ||= []
        payment.csn.append(request.request_parameters)

        case csn.status
        when :accept, :fulfilled
          payment.last_status = csn.status
          payment.save
        when :verified
          payment.last_status = :verified
          payment.save
          if payment.order.cart.finalize!
          else
            logger.error 'Deko CSN Return errored on cart'
            raise 'Cart errored'
          end
        else
          payment.last_status = :other
          payment.save
        end
        head :no_content
      end
    end
  end
end

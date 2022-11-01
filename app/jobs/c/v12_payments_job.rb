# frozen_string_literal: true

module C
  class V12PaymentsJob
    include SuckerPunch::Job

    def process_unpaid_payments
      C::BackgroundJob.process('V12: Get Orders') do
        payables = C::PaymentMethod::V12Finance.where(
          last_status: %i[acknowledged accepted]
        )

        payables.each do |payable|
          last_status = payable.last_status.to_sym
          new_status = payable.update_status!

          # > 30 minutes and just acknowleged, or not paid and no cart, cancel
          if (new_status == :acknowledged && payable.created_at < 30.minutes.ago) ||
             (new_status != :awaiting_fulfilment && (payable.payment&.order&.cart).nil?)
            if payable.payment
              payable.payment.cancel!
              payable.payment.destroy
            else
              payable.cancel!
            end
          elsif last_status != new_status
            if new_status == :awaiting_fulfilment
              payable.payment.order.cart.finalize!
            end
          end
        end
      end
    end

    def perform(*_args)
      process_unpaid_payments
    end
  end
end

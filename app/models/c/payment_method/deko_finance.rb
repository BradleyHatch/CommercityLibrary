# frozen_string_literal: true

require 'deko'

module C
  module PaymentMethod
    class DekoFinance < ApplicationRecord
      include Payable

      enum last_status: %i[not_verified accept refer verified fulfilled other]

      validates :unique_reference, presence: true, uniqueness: true
      validates :last_status, presence: true

      def finalize!(user_params = {})
        # Nothing to do
        true
      end

      def paid?
        verified?
      end

      def off_site_confirmation?
        true
      end

      def fulfil
        rq = Deko::FulfilmentRequest.new(deko_id, Time.zone.now.iso8601)
        rq.make_request
      end
    end
  end
end

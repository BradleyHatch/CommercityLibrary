# frozen_string_literal: true

module C
  module PaymentMethod
    class Worldpay < ApplicationRecord
      include Payable

      def finalize!(user_params = {})
        billingAddress = encode_address(
          order.billing_address || order.shipping_address
        )

        client = ::Worldpay.new(ENV['WORLDPAY_SERVER_KEY'])
        response = client.createOrder(
          'token' => payment_token,
          'amount' => payment.amount_paid.to_f,
          'currencyCode' => 'GBP',
          'name' => order.name,
          'orderDescription' => "#{C.store_name} order #{order.order_number}",
          'billingAddress' => billingAddress,
          'customerOrderCode' => order.order_number
        )
        if response['body']['paymentStatus'] == 'SUCCESS'
          update(order_code: response['body']['orderCode'])
          true
        else
          logger.error 'Worldpay Payment failed!'
          logger.error response.to_yaml
          false
        end
      end

      def paid?
        order_code.present?
      end

      def encode_address(addr)
        {
          'address1' => addr.address_one,
          'address2' => addr.address_two,
          'address3' => addr.address_three,
          'postalCode' => addr.postcode,
          'city' => addr.city,
          'state' => addr.region,
          'countryCode' => addr.country.iso2
        }
      end
    end
  end
end

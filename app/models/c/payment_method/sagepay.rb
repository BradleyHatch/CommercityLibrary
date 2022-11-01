# frozen_string_literal: true

module C
  module PaymentMethod
    class Sagepay < ApplicationRecord
      include Payable

      ##
      # Make the transaction. This is an all or nothing operation.
      #
      # The +r+ hash is the configuration hash mentioned in
      # SagepayAPI#make_transaction. Currently hard coded to use GBP.
      #
      # If the transaction is accepted, sets the transaction_id on the record
      # and returns +true+. Otherwise, logs the error and returns +false+.
      def finalize!(user_params = {})
        if self.threed_secure_status.present? && self.threed_secure_status == 'ok'
          return true
        end

        
        address = encode_address(
          order.billing_address || order.shipping_address
        )
        
        base = Rails.env === "development" ? C.dev_site_url : C.prod_site_url

        # Rails.application.routes.url_helpers.sagepay_3dsf_return_checkout_path
        return_path = "/cart/checkout/sagepay_3dsc_return"
        return_url = "#{base}#{return_path}"

        name_parts = order.customer.name.split(' ')
        first_name = name_parts.first
        last_name = name_parts.drop(1).join(' ')

        if last_name.blank?
          last_name = first_name
        end
        
        r = {
          'transactionType': 'Payment',
          'paymentMethod': {
            'card': {
              'merchantSessionKey': merchant_session_key,
              'cardIdentifier': card_identifier
            }
          },
          'vendorTxCode': order.order_number,
          'amount': payment.amount_paid.fractional,
          'currency': 'GBP',
          'description': order.order_number,
          'apply3DSecure': 'UseMSPSetting',
          'customerFirstName': first_name,
          'customerLastName': last_name,
          'billingAddress': address,
          'entryMethod': 'Ecommerce',
          "strongCustomerAuthentication": {
            "notificationURL": return_url,
            "transType": "GoodsAndServicePurchase",
            "challengeWindowSize": "Small",
            "browserJavascriptEnabled": true,
            "browserUserAgent": user_params['browserUserAgent'],
            "browserIP": user_params['browserIP'],
            "browserAcceptHeader": user_params['browserAcceptHeader'],
            "browserJavaEnabled": user_params['browserJavaEnabled'],
            "browserLanguage": user_params['browserLanguage'],
            "browserColorDepth": user_params['browserColorDepth'],
            "browserScreenHeight": user_params['browserScreenHeight'],
            "browserScreenWidth": user_params['browserScreenWidth'],
            "browserTZ": user_params['browserTZ'],
          },
        }

        begin
          transaction = C::SAGEPAY_API.make_transaction(r)
        rescue SagepayAPIRequestError, SagepayAPITransactionError => e
          logger.error e.message
          logger.error e.body
          return false
        end

        update(transaction_id: transaction['transactionId'])

        # returning the full transaction data so checkout controller can handle 3ds redirects
        transaction
      end

      ##
      # As the transaction_id is only set once the transaction is made, we can
      # use that to indicate whether the user has paid or not.
      def paid?
        transaction_id.present?
      end

      ##
      # Converts a C::Address to a Sagepay-friendly address hash.
      def encode_address(addr)
        {
          'address1' => addr.address_one,
          'address2' => addr.address_two,
          'postalCode' => addr.postcode,
          'city' => addr.city,
          'country' => addr.country.iso2
        }
      end
    end
  end
end

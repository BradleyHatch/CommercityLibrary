# frozen_string_literal: true

module C
  module PaymentMethod
    class PaypalExpress < ApplicationRecord
      include Payable

      def finalize!(user_params = {})
        countries_match = ensure_order_address

        if countries_match
          response = C::EXPRESS_GATEWAY.purchase(payment.amount_paid_pennies, express_payment_options)
          return true if response.params['ack'].starts_with?('Success')
        end

        logger.error 'Paypal Express Payment failed!'
        logger.error response.to_yaml

        payment.order.cart.update!(country_didnt_match_from_paypal: true) if !countries_match

        false
      end

      def express_payment_options
        {
          ip: ip,
          token: payment_token,
          payer_id: payer_id,
          currency: 'GBP'
        }
      end

      def paid?
        true
      end

      # Request payment details from Paypal and then checking if country codes are consistent
      def ensure_order_address
        details = C::EXPRESS_GATEWAY.details_for(payment_token)
        params = details.params

        country_code_from_paypal = params["PaymentDetails"]["ShipToAddress"] ? params["PaymentDetails"]["ShipToAddress"]["Country"] : params["country"]
        country_from_paypal = C::Country.find_by(iso2: country_code_from_paypal)
        country_from_checkout = payment.order.shipping_address.country


        if country_from_paypal.present? && country_from_checkout.present?
          pp_iso2 = country_from_paypal.iso2
          co_iso2 = country_from_checkout.iso2

          # Because some people want to have England/Wales/NI/Scotland as separate countries, they are stored with fake iso2's of GB_
          # Paypal only supports real ones so they discard the shipping address if it's not valid
          # so here, we check if it has the hack prefix and then send up GB which will we will check here if it's just a GB country
          if co_iso2.include?("GB_")
            co_iso2 = "GB"
          end

          if pp_iso2 == co_iso2
            copy_address_from_paypal(params)
            true
          else
            false
          end
        else
          false
        end
      end

      # Copy the billing address from Paypal
      def copy_address_from_paypal(params)
        address_attributes = params["BillingAddress"]
        return unless address_attributes

        new_address_attributes = {
          name: address_attributes['Name'],
          address_one: address_attributes['Street1'],
          address_two: address_attributes['Street2'],
          city: address_attributes['CityName'],
          region: address_attributes['StateOrProvince'],
          country: C::Country.find_by(iso2: address_attributes['Country']),
          postcode: address_attributes['PostalCode']
        }

        if order.billing_address
          order.billing_address.update!(new_address_attributes)
        else
          billing_address = C::Address.create!(new_address_attributes)
          order.update!(billing_address: billing_address)
        end
        order.save!
      end

      def transaction_id
        payment_token
      end
    end
  end
end

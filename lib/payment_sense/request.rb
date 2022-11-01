# frozen_string_literal: true

require 'payment_sense/utils'

##
# Works in almost exactly the same way as Worldpay Cardsave, see the
# documentation for that.
#
# Official documentation: http://developers.paymentsense.co.uk/hosted-integration-resources/
#
# ==== Environment Variables
#
# * +PAYMENT_SENSE_MERCHANT_ID+: The gateway ID code for the merchant.
# * +PAYMENT_SENSE_PSK+: The pre-shared key for the Merchant.
# * +PAYMENT_SENSE_PASSWORD+: The gateway password. This is not the account
#   password, but the password set in the configuration screen specifically for
#   online payment.

module PaymentSense
  class Request
    def initialize(data = {})
      @order = data.delete(:order)
      @data = {
        pre_shared_key: ENV['PAYMENT_SENSE_PSK'],
        merchant_id: ENV['PAYMENT_SENSE_MERCHANT_ID'],
        password: ENV['PAYMENT_SENSE_PASSWORD'],
        transaction_type: 'SALE',
        transaction_date_time: Time.zone.now,
        result_delivery_method: 'POST',
        cv2_mandatory: 'true',
        address_1_mandatory: 'true',
        city_mandatory: 'true',
        post_code_mandatory: 'true',
        state_mandatory: 'true',
        country_mandatory: 'true',
        echo_card_type: 'true'
      }.merge(data)
    end

    def get_value(key, options = {})
      options = options.clone
      method = options.delete(:method)
      if method && options.any?
        send(method, options)
      elsif method
        send(method)
      else
        @data[key]
      end
    end

    def to_query_string(fields = Utils::REQUEST_HASH_FIELDS,
                        lookup_methods = Utils::REQUEST_LOOKUP_METHODS)
      fields.map do |key|
        options = lookup_methods[key]
        Utils.parameterize(key, get_value(key, options || {}))
      end.join('&')
    end

    def to_form(fields = Utils::REQUEST_FORM_FIELDS,
                lookup_methods = Utils::REQUEST_LOOKUP_METHODS)
      form_contents = fields.map do |key|
        options = lookup_methods[key]
        Utils.fieldify(key, get_value(key, options || {}))
      end.join("\n")
      '<form id="payment_sense_form" method="POST"' \
        "action=\"#{Utils::FORM_URL}\">\n#{form_contents}\n</form>"
    end

    # Value Methods

    def digest
      Digest::SHA1.hexdigest(to_query_string)
    end

    def amount
      @order.total_price_with_tax_and_delivery_pennies.fractional.to_s
    end

    def currency_code
      @order.total_price_with_tax_and_delivery_pennies.currency.iso_numeric.to_s
    end

    def country_code
      country = from_address(map: :country)
      country.numeric
    end

    def order_number
      @order.order_number
    end

    def from_address(options)
      mapped_attr = options.fetch(:map)
      @order.billing_address.send(mapped_attr)
    end

    def from_order(options)
      mapped_attr = options.fetch(:map)
      @order.send(mapped_attr)
    end

    def transaction_time
      @data[:transaction_date_time].strftime(Utils::ISO_8601_FORMAT)
    end
  end
end

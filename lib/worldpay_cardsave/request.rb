# frozen_string_literal: true

require 'worldpay_cardsave/utils'

##
# See https://www.cardsave.net/dev-downloads for the Integration Guide and API
# Documentation.
#
# We use the Hosted Payment Form method, but the Transparent Redirect could
# eventually be used with some slight adaptations.
#
# With the hosted form, we build an HTML form with the required data serialized
# as hidden fields. The user's browser then submits the form, generally by the
# user clicking a button tied to the form with Javascript.
#
# The hashing method used at the moment is SHA1, but HMAC-SHA1 should be
# considered for the future. This will require changing both the way the
# digest is computed and the fields included in the request. See the
# official documentation for more detail.
#
# ==== Environment Variables
#
# * +WORLDPAY_CARDSAVE_MERCHANT_ID+: The Cardsave ID code for the merchant.
# * +WORLDPAY_CARDSAVE_PSK+: The pre-shared key for the Merchant.
# * +WORLDPAY_CARDSAVE_PASSWORD+: The password for Cardsave. This is not the
#   account password, but the password set in the configuration screen
#   specifically for online payment.

module WorldpayCardsave
  ##
  # Serializes and normalises requisite data from the order and builds an HTML
  # form that redirects the user to the Cardsave payment form.
  #
  # Configuration constants are defined in the Utils class.

  class Request
    ##
    # Builds a Request.
    #
    # ==== Options
    #
    # * +order+: The order from which to build the payment request.
    #
    # Any other fields can be provided to override the default options, defined
    # in the initializer.
    def initialize(data = {})
      @order = data.delete(:order) || {}
      @data = {
        pre_shared_key: ENV['WORLDPAY_CARDSAVE_PSK'],
        merchant_id: ENV['WORLDPAY_CARDSAVE_MERCHANT_ID'],
        password: ENV['WORLDPAY_CARDSAVE_PASSWORD'],
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

    ##
    # Uses the parameters passed to it to determine whether to look for the
    # requested field in either a specified method or in the data hash.
    #
    # ==== Options
    #
    # * +method+ (Optional): The Request instance method to call to fetch the
    #   data.
    #
    # Any other options are passed as options to the method specified in the
    # options, if present.

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

    ##
    # Collects the data and builds a query string, similar to one used in a
    # URL. The query string is then used to compute the digest of the request
    # data.
    #
    # ==== Parameters
    #
    # * +fields+: The fields to include in the query string.
    # * +lookup_methods+: A hash containing the configuration of which fields
    #   require a custom lookup method. See the Utils class for the example
    #   format.

    def to_query_string(fields = Utils::REQUEST_HASH_FIELDS,
                        lookup_methods = Utils::REQUEST_LOOKUP_METHODS)
      fields.map do |key|
        options = lookup_methods[key]
        Utils.parameterize(key, get_value(key, options || {}))
      end.join('&')
    end

    ##
    # Collects the data and builds an HTML form with it. The form requires
    # slightly different fields to the query string, such as the digest of the
    # request data.
    #
    # ==== Parameters
    #
    # * +fields+: The fields to include in the form.
    # * +lookup_methods+: A hash containing the configuration of which fields
    #   require a custom lookup method. See the Utils class for the example
    #   format.

    def to_form(fields = Utils::REQUEST_FORM_FIELDS,
                lookup_methods = Utils::REQUEST_LOOKUP_METHODS)
      form_contents = fields.map do |key|
        options = lookup_methods[key]
        Utils.fieldify(key, get_value(key, options || {}))
      end.join("\n")
      '<form id="worldpay_cardsave_form" method="POST"' \
        "action=\"#{Utils::FORM_URL}\">\n#{form_contents}\n</form>"
    end

    # Value Methods

    ##
    # Computes the digest of the request data using the query string. This is
    # then included in the built form to provide some weak (IMO) verification
    # of the merchant's ID.
    def digest
      Digest::SHA1.hexdigest(to_query_string)
    end

    ##
    # Amount to request payment for. Should be in the minor currency, so
    # £12,345.67 would be 1234567.
    def amount
      @order.total_price_with_tax_and_delivery_pennies.fractional.to_s
    end

    ##
    # Returns the ISO 3166-1 numeric country code for the currency to request
    # payment in. Ruby-Money provides this in Money objects.
    #
    # See https://en.wikipedia.org/wiki/ISO_3166-1_numeric for a list of
    # country codes.
    def currency_code
      @order.total_price_with_tax_and_delivery_pennies.currency.iso_numeric.to_s
    end

    ##
    # Returns the ISO 3166-1 numeric country code for the country in the
    # billing address.
    #
    # See https://en.wikipedia.org/wiki/ISO_3166-1_numeric for a list of
    # country codes.
    def country_code
      country = from_address(map: :country)
      country.numeric
    end

    ##
    # Returns the order reference number.
    def order_number
      @order.order_number
    end

    ##
    # Fetches the requested attribute from the billing address of the order.
    #
    # ==== Options
    # * +map+: The method to call on the address object.
    def from_address(options)
      mapped_attr = options.fetch(:map)
      @order.billing_address.send(mapped_attr)
    end

    ##
    # Fetches the requested attribute from the order.
    #
    # ==== Options
    # * +map+: The method to call on the order object.
    def from_order(options)
      mapped_attr = options.fetch(:map)
      @order.send(mapped_attr)
    end

    ##
    # Returns the transaction time of the order in the appropriate time format,
    # which is more or less ISO 8601.
    # See Utils::ISO_8601_FORMAT for the strftime format string.
    def transaction_time
      @data[:transaction_date_time].strftime(Utils::ISO_8601_FORMAT)
    end
  end
end

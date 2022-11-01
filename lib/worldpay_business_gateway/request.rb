# frozen_string_literal: true

require 'worldpay_business_gateway/utils'

##
# See http://www.worldpay.com/global/support/guides/business-gateway for
# official documentation. If you can find it.
#
# Also see Commercity's README.
#
# We use a Hosted Payment Form, which is very similar to Worldpay Cardsave.
#
# With the hosted form, we build an HTML form with the required data serialized
# as hidden fields. The user's browser then submits the form, generally by the
# user clicking a button tied to the form with Javascript.
#
# The hashing method used at the moment is MD5, but either HMAC-MD5 or
# HMAC-SHA1 should be considered for the future, if available. This will
# require changing both the way the digest is computed and the fields included
# in the request. See the official documentation for more detail.
#
# ==== Environment Variables
#
# * +WORLDPAY_BG_INSTALLATION_ID+: The Installation ID code for the merchant.
# * +WORLDPAY_BG_SECRET+: The secret string set in the Merchant Management
#   System.
# * +WORLDPAY_BG_LIVE+: If set, makes the integration create live transactions
#   instead of test ones.
# * +WORLDPAY_BG_RESPONSE_PASSWORD+: The secret password set in the MMS to
#   identify who sent a Response.

module WorldpayBusinessGateway
  ##
  # Serializes and normalises requisite data from the order and builds an HTML
  # form that redirects the user to the hosted payment form.
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
      @order = data.delete(:order)
      @data = {
        inst_id: ENV['WORLDPAY_BG_INSTALLATION_ID'],
        secret_string: ENV['WORLDPAY_BG_SECRET'],
        auth_mode: 'A',
        hide_currency: true
      }.merge(data)
      @data[:test_mode] = ENV['WORLDPAY_BG_LIVE'] ? 0 : 100
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
    # Collects the data and builds a secret string. The string is then used to
    # compute the digest of the request
    # data.
    #
    # ==== Parameters
    #
    # * +fields+: The fields to include in the query string.
    # * +lookup_methods+: A hash containing the configuration of which fields
    #   require a custom lookup method. See the Utils class for the example
    #   format.

    def secret(fields = Utils::REQUEST_HASH_FIELDS,
               lookup_methods = Utils::REQUEST_LOOKUP_METHODS)
      fields.map do |key|
        options = lookup_methods[key]
        get_value(key, options || {})
      end.join(':')
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
        val =  get_value(key, options || {})
        next if key == :MC_callback && val.blank?
        Utils.fieldify(key, val)
      end.join("\n")
      '<form id="worldpay_bg_form" method="POST"' \
        "action=\"#{Utils::FORM_URL}\">\n#{form_contents}\n</form>"
    end

    # Value Methods

    ##
    # Computes the digest of the request data using the query string. This is
    # then included in the built form to provide some weak (IMO) verification
    # of the merchant's ID.
    def digest
      Digest::MD5.hexdigest(secret)
    end

    def amount
      @order.total_price_with_tax_and_delivery_pennies.to_s
    end

    ##
    # Returns the ISO 3166-2 country code for the currency to request payment
    # in. Ruby-Money provides this in Money objects.
    #
    # See https://en.wikipedia.org/wiki/ISO_3166-2 for a list of country codes.
    def currency_code
      @order.total_price_with_tax_and_delivery_pennies.currency.iso_code
    end

    ##
    # Returns the ISO 3166-2 country code for the country in the billing
    # address.
    #
    # See https://en.wikipedia.org/wiki/ISO_3166-2 for a list of country codes.
    def country_code
      country = from_address(map: :country)
      country.iso2
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
    # Returns environment variable for custom payment response url.
    def mc_callback
      ENV['WORLDPAY_BG_MC_CALLBACK']
    end
  end
end

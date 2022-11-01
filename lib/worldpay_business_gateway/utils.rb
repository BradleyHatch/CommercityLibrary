# frozen_string_literal: true

module WorldpayBusinessGateway
  class Utils
    # The location to post the HTML request form
    FORM_URL = if ENV['WORLDPAY_BG_LIVE']
                 'https://secure.worldpay.com/wcc/purchase'
               else
                 'https://secure-test.worldpay.com/wcc/purchase'
               end

    # A hash of exceptions from the standard camelize inflection.
    # e.g. callback_url --> CallbackURL
    CAMELIZE_EXCEPTIONS = {
      MC_callback: 'MC_callback'
    }.freeze

    ##
    # Configuration for custom lookup methods on the request.
    #
    # The format is as follows:
    #   field_name: { method: :method_to_call, map: :option_for_method }
    #
    # The +field_name+ is a symbol for the method that is initially called on
    # the request. The +method_to_call+ is a symbol for the method that the
    # lookup method calls. Any further keys for the inner hash are passed to
    # +method_to_call+ as options.
    #
    # E.g.:
    #   address_1: { method: :from_address, map: :address_one }
    #
    # In the example, +map+ would be passed to +from_address+, which
    # would then call +address_one+ on the address object.

    REQUEST_LOOKUP_METHODS = {
      signature: { method: :digest },
      amount: { method: :amount },
      currency: { method: :currency_code },
      cart_id: { method: :order_number },
      customer_name: { method: :from_order, map: :name },
      address_1: { method: :from_address, map: :address_one },
      address_2: { method: :from_address, map: :address_two },
      address_3: { method: :from_address, map: :address_three },
      town: { method: :from_address, map: :city },
      region: { method: :from_address, map: :region },
      postcode: { method: :from_address, map: :postcode },
      country: { method: :country_code },
      email: { method: :from_order, map: :email },
      tel: { method: :from_order, map: :phone },
      MC_callback: { method: :mc_callback }
    }.freeze

    # A list of fields in lower Camel Case that are used in the secret string
    # for the digest.
    REQUEST_HASH_FIELDS = %i[
      secret_string
      inst_id
      amount
      currency
      cart_id
    ].freeze

    # A list of fields in snake case that are sent in the HTML request form.
    REQUEST_FORM_FIELDS = %i[
      test_mode
      inst_id
      cart_id
      amount
      currency
      address_1
      address_2
      address_3
      town
      region
      postcode
      country
      name
      email
      tel
      hide_currency
      auth_mode
      signature
      MC_callback
    ].freeze

    # A list of fields in lower Camel Case that are used for storage and in the
    # query string for the digest.
    RESPONSE_RETURN_FIELDS = %w[
      country
      authCost
      msgType
      routeKey
      transId
      countryMatch
      rawAuthMessage
      authCurrency
      charenc
      compName
      rawAuthCode
      amountString
      installation
      currency
      tel
      fax
      lang
      countryString
      email
      transStatus
      _SP.charEnc
      amount
      address
      transTime
      cost
      town
      address3
      address2
      address1
      cartId
      postcode
      ipAddress
      cardType
      authAmount
      authMode
      instId
      displayAddress
      AAV
      testMode
      name
      callbackPW
      region
      AVS
      desc
      authAmountString
      controller
      action
    ].freeze

    ##
    # Returns the lower Camel Case version of the given key. Respects
    # exceptions made in CAMELIZE_EXCEPTIONS.
    #
    # ==== Parameters
    #
    # * +key+: The key to convert to Upper Camel Case.
    def self.camelize(key)
      CAMELIZE_EXCEPTIONS[key] || key.to_s.camelize(:lower)
    end

    ##
    # Returns a query string key-value pair. Not actually used anywhere but the
    # tests.
    #
    # ==== Parameters
    #
    # * +key+: The key of the pair, which will be converted to lower Camel
    #   Case.
    # * +value+: The value of the pair, which will be converted to a string.
    def self.parameterize(key, value)
      "#{camelize(key)}=#{value}"
    end

    ##
    # Returns a key-value pair as a hidden HTML form field.
    # Yes, I know. The name is stupid.
    #
    # ==== Parameters
    #
    # * +key+: The key of the pair, which will be converted to lower Camel
    #   Case.
    # * +value+: The value of the pair, which will be converted to a string.
    def self.fieldify(key, value)
      "<input type=\"hidden\" value=\"#{value}\" name=\"#{camelize(key)}\">"
    end
  end
end

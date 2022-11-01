# frozen_string_literal: true

module WorldpayCardsave
  class Utils
    # The location to post the HTML request form
    FORM_URL = 'https://mms.cardsaveonlinepayments.com/Pages/PublicPages/PaymentForm.aspx'

    # The strftime format used by Cardsave
    ISO_8601_FORMAT = '%Y-%m-%d %H:%M:%S %:z'

    # A hash of exceptions from the standard camelize inflection.
    # e.g. callback_url --> CallbackURL
    CAMELIZE_EXCEPTIONS = {
      callback_url: 'CallbackURL',
      order_id: 'OrderID',
      merchant_id: 'MerchantID',
      cv2_mandatory: 'CV2Mandatory',
      echo_avs_check_result: 'EchoAVSCheckResult',
      echo_cv2_check_result: 'EchoCV2CheckResult',
      avs_override_policy: 'AVSOverridePolicy',
      cv2_override_policy: 'CV2OverridePolicy',
      server_result_url: 'ServerResultURL',
      server_result_url_cookie_variables: 'ServerResultURLCookieVariables',
      server_result_url_form_variables: 'ServerResultURLFormVariables',
      server_result_url_query_string_variables: 'ServerResultURLQueryStringVariables'
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
      hash_digest: { method: :digest },
      amount: { method: :amount },
      currency_code: { method: :currency_code },
      order_id: { method: :order_number },
      transaction_date_time: { method: :transaction_time },
      customer_name: { method: :from_order, map: :name },
      address_1: { method: :from_address, map: :address_one },
      address_2: { method: :from_address, map: :address_two },
      address_3: { method: :from_address, map: :address_three },
      city: { method: :from_address, map: :city },
      state: { method: :from_address, map: :region },
      post_code: { method: :from_address, map: :postcode },
      country_code: { method: :country_code },
      email_address: { method: :from_order, map: :email },
      phone_number: { method: :from_order, map: :phone }
    }.freeze

    ##
    # Configuration for custom lookup methods on the request. See
    # REQUEST_LOOKUP_METHODS for configuration.

    RESPONSE_LOOKUP_METHODS = {
      transaction_date_time: { method: :date_time },
      pre_shared_key: { method: :from_config },
      password: { method: :from_config }
    }.freeze

    # A list of fields in Upper Camel Case that are used for storage and in the
    # query string for the digest.
    RESPONSE_COMMON_FIELDS = %w[
      StatusCode
      Message
      PreviousStatusCode
      PreviousMessage
      CrossReference
      AddressNumericCheckResult
      PostCodeCheckResult
      CV2CheckResult
      ThreeDSecureAuthenticationCheckResult
      CardType
      CardClass
      CardIssuer
      CardIssuerCountryCode
      CardNumberFirstSix
      CardNumberLastFour
      CardExpiryDate
      Amount
      DonationAmount
      CurrencyCode
      OrderID
      TransactionType
      TransactionDateTime
      OrderDescription
      LineItemSalesTaxAmount
      LineItemSalesTaxDescription
      LineItemQuantity
      LineItemAmount
      LineItemDescription
      CustomerName
      Address1
      Address2
      Address3
      Address4
      City
      State
      PostCode
      CountryCode
      EmailAddress
      PhoneNumber
      DateOfBirth
      ShippingName
      ShippingAddress1
      ShippingAddress2
      ShippingAddress3
      ShippingAddress4
      ShippingCity
      ShippingState
      ShippingPostCode
      ShippingCountryCode
      ShippingEmailAddress
      ShippingPhoneNumber
      PrimaryAccountName
      PrimaryAccountNumber
      PrimaryAccountDateOfBirth
      PrimaryAccountPostCode
    ].freeze

    # A list of fields in Upper Camel Case that are used in the query string
    # for the digest.
    RESPONSE_HASH_FIELDS = (
      %w[
        PreSharedKey
        MerchantID
        Password
      ] + RESPONSE_COMMON_FIELDS
    ).freeze

    RESPONSE_STORE_FIELDS = (
      %w[
        MerchantID
      ] + RESPONSE_COMMON_FIELDS
    ).freeze

    # A list of fields in snake case that are used for both the HTML
    # request form and the query string for the digest.
    REQUEST_COMMON_FIELDS = %i[
      amount
      currency_code
      echo_card_type
      order_id
      transaction_type
      transaction_date_time
      callback_url
      order_description
      customer_name
      address_1
      address_2
      address_3
      address_4
      city
      state
      post_code
      country_code
      email_address
      phone_number
      cv2_mandatory
      address_1_mandatory
      city_mandatory
      post_code_mandatory
      state_mandatory
      country_mandatory
      server_result_url
      server_result_url_cookie_variables
      server_result_url_form_variables
      server_result_url_query_string_variables
    ].freeze

    # A list of fields in snake case that are used in the query string
    # for the digest.
    REQUEST_HASH_FIELDS = (
      %i[
        pre_shared_key
        merchant_id
        password
      ] + REQUEST_COMMON_FIELDS
    ).freeze

    # A list of fields in snake case that are used in the HTML request form.
    REQUEST_FORM_FIELDS = (
      %i[
        hash_digest
        merchant_id
      ] + REQUEST_COMMON_FIELDS
    ).freeze

    ##
    # Returns the Upper Camel Case version of the given key. Respects
    # exceptions made in CAMELIZE_EXCEPTIONS.
    #
    # ==== Parameters
    #
    # * +key+: The key to convert to Upper Camel Case.
    def self.camelize(key)
      CAMELIZE_EXCEPTIONS[key] || key.to_s.camelize
    end

    ##
    # Returns a query string key-value pair.
    #
    # ==== Parameters
    #
    # * +key+: The key of the pair, which will be converted to Upper Camel
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
    # * +key+: The key of the pair, which will be converted to Upper Camel
    #   Case.
    # * +value+: The value of the pair, which will be converted to a string.
    def self.fieldify(key, value)
      "<input type=\"hidden\" value=\"#{value}\" name=\"#{camelize(key)}\">"
    end
  end
end

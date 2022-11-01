# frozen_string_literal: true

module PaymentSense
  class Utils
    FORM_URL = 'https://mms.paymentsensegateway.com/Pages/PublicPages/PaymentForm.aspx'

    ISO_8601_FORMAT = '%Y-%m-%d %H:%M:%S %:z'

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

    RESPONSE_LOOKUP_METHODS = {
      transaction_date_time: { method: :date_time },
      pre_shared_key: { method: :from_config },
      password: { method: :from_config }
    }.freeze

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

    REQUEST_HASH_FIELDS = (
      %i[
        pre_shared_key
        merchant_id
        password
      ] + REQUEST_COMMON_FIELDS
    ).freeze

    REQUEST_FORM_FIELDS = (
      %i[
        hash_digest
        merchant_id
      ] + REQUEST_COMMON_FIELDS
    ).freeze

    def self.camelize(key)
      CAMELIZE_EXCEPTIONS[key] || key.to_s.camelize
    end

    def self.parameterize(key, value)
      "#{camelize(key)}=#{value}"
    end

    # Yes, I know.
    def self.fieldify(key, value)
      "<input type=\"hidden\" value=\"#{value}\" name=\"#{camelize(key)}\">"
    end
  end
end

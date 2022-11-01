# frozen_string_literal: true

require 'worldpay_business_gateway/utils'

module WorldpayBusinessGateway
  ##
  # Wraps a response from the Worldpay server. Unlike Cardsave, the user is not
  # redirected back to the checkout. Instead, a POST request is sent by the
  # Worldpay server at an unspecified time after the payment is completed.
  #
  # Otherwise, the response works in a similar manner to the Cardsave
  # equivalent.
  #
  # See the official documentation for more details.

  class Response
    # The transaction status indicating success.
    SUCCESS = 'Y'

    # The transaction status indicating success.
    INSTALLATION_ID = ENV['WORLDPAY_BG_INSTALLATION_ID']

    # The password set in the MMS to validate who sent the Response.
    RESPONSE_PASSWORD = ENV['WORLDPAY_BG_RESPONSE_PASSWORD']

    ##
    # Builds a Response.
    #
    # ==== Parameters
    #
    # * +params+: A params hash of the response from Worldpay.
    def initialize(params = {})
      @data = {
      }.merge(params.except(%w[action controller])).freeze
    end

    ## Hash/data validity

    ##
    # Returns whether the response is for the correct installation.
    def installation_matches?
      installation == INSTALLATION_ID
    end

    ##
    # Returns whether the callback password matches the expected response
    # password.
    def password_matches?
      return true if RESPONSE_PASSWORD.blank?
      callback_p_w == RESPONSE_PASSWORD
    end

    ##
    # Returns whether the response is considered valid.
    def valid?
      installation_matches? && password_matches?
    end

    ##
    # Returns whether the response is considered invalid.
    def invalid?
      !valid?
    end

    ## Transaction status information

    ##
    # Returns whether the response succeeded by comparing the transaction
    # status with the known success code, which is 'Y'. See the documentation
    # for other statuses.
    def success?
      trans_status == SUCCESS
    end

    ## Value coercion and retrieval

    ##
    # Returns the amount paid as a Money object in the currency of the
    # transaction.
    def amount_paid
      Money.from_amount(
        amount.to_f,
        Money::Currency.find(currency)
      )
    end

    ## General data retrieval

    ##
    # Any unknown instance methods on the response will first check to see if
    # the key exists in the response params, and falling back to the super
    # method.

    def method_missing(method_name, *args, &block)
      camel = WorldpayBusinessGateway::Utils.camelize(method_name)
      if @data.keys.include?(camel)
        @data[camel]
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      camel = WorldpayBusinessGateway::Utils.camelize(method_name)
      @data.keys.include?(camel) || super
    end

    ##
    # Returns the value of the given key as a Time, using the seconds since the
    # UNIX epoch as the strptime format.

    def date_time(key, _options = {})
      Time.strptime(@data[key], '%Q')
    end
  end
end

# frozen_string_literal: true

require 'worldpay_cardsave/utils'

module WorldpayCardsave
  ##
  # Wraps a response from the Cardsave server. We use the POST method of result
  # delivery, meaning that the user is redirected back to our site after
  # paying.
  #
  # See the official documentation for more details.

  class Response
    # The merchant ID from the environment cached in a constant.
    MERCHANT_ID = ENV['WORLDPAY_CARDSAVE_MERCHANT_ID']

    # The status code indicating success.
    SUCCESS = '0'

    ##
    # Builds a Response.
    #
    # ==== Parameters
    #
    # * +params+: A params hash of the response from Cardsave.
    def initialize(params = {})
      @data = {
        'PreSharedKey' => ENV['WORLDPAY_CARDSAVE_PSK'],
        'Password' => ENV['WORLDPAY_CARDSAVE_PASSWORD']
      }.merge(params).freeze
    end

    ##
    # Collects the data and builds a query string, similar to one used in a
    # URL. The query string is then used to compute the digest of the response
    # data for verification and validity.
    #
    # ==== Parameters
    #
    # * +fields+: The fields to include in the query string.

    def to_query_string(fields = Utils::RESPONSE_HASH_FIELDS)
      present_fields = fields.select { |field| @data.keys.include?(field) }
      present_fields.map { |field| "#{field}=#{@data[field]}" }.join('&')
    end

    ## Hash/data validity

    ##
    # Computes the digest of the request data using the query string. This is
    # used to confirm the validity of the response and that it came from
    # Cardsave's server.
    def digest
      Digest::SHA1.hexdigest(to_query_string)
    end

    ##
    # Returns whether the hash digest in the response matches the locally
    # computed digest.
    def hash_matches?
      hash_digest == digest
    end

    ##
    # Returns whether the merchant ID in the response matches the local one.
    def merchant_id_matches?
      merchant_id == MERCHANT_ID
    end

    ##
    # Returns whether the response is considered valid.
    def valid?
      merchant_id_matches? && hash_matches?
    end

    ##
    # Returns whether the response is considered invalid.
    def invalid?
      !valid?
    end

    ## Transaction status information

    ##
    # Returns whether the response succeeded by comparing the status code with
    # the known success code, which is 0. See the below list for the common
    # status codes.
    #
    # * 0: transaction successful
    # * 4: card referred
    # * 5: card declined
    # * 20: duplicate transaction
    # * 30: exception
    def success?
      status_code == SUCCESS
    end

    ## Value coercion and retrieval

    ##
    # Returns the amount paid as a Money object in the currency of the
    # transaction.
    def amount_paid
      Money.new(
        amount,
        Money::Currency.find_by_iso_numeric(currency_code)
      )
    end

    ## General data retrieval

    ##
    # Any unknown instance methods on the response will first check to see if a
    # custom lookup method exists for the method name, falling back to if the
    # key exists in the response params, and finally falling back to the super
    # method.

    def method_missing(method_name, *args, &block)
      camel = Utils.camelize(method_name)
      if (options = Utils::RESPONSE_LOOKUP_METHODS[method_name])
        send(options[:method], method_name, options.except(:method))
      elsif @data.key?(camel)
        @data[camel]
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      camel = Utils.camelize(method_name)
      Utils::RESPONSE_LOOKUP_METHODS.key?(method_name) ||
        @data.key?(camel) || super
    end

    ##
    # Returns the value of the given key as a Time, using the
    # Utils::ISO_8601_FORMAT as the strptime format.

    def date_time(key, _options = {})
      Time.zone.strptime(@data[key], Utils::ISO_8601_FORMAT)
    end
  end
end

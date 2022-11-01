# frozen_string_literal: true

require 'payment_sense/utils'

module PaymentSense
  class Response
    MERCHANT_ID = ENV['PAYMENT_SENSE_MERCHANT_ID']

    SUCCESS = '0'

    def initialize(params = {})
      @data = {
        'PreSharedKey' => ENV['PAYMENT_SENSE_PSK'],
        'Password' => ENV['PAYMENT_SENSE_PASSWORD']
      }.merge(params).freeze
    end

    def to_query_string(fields = Utils::RESPONSE_HASH_FIELDS)
      present_fields = fields.select { |field| @data.keys.include?(field) }
      present_fields.map { |field| "#{field}=#{@data[field]}" }.join('&')
    end

    ## Hash/data validity

    def digest
      Digest::SHA1.hexdigest(to_query_string)
    end

    def hash_matches?
      hash_digest == digest
    end

    def merchant_id_matches?
      merchant_id == MERCHANT_ID
    end

    def valid?
      merchant_id_matches? && hash_matches?
    end

    def invalid?
      !valid?
    end

    ## Transaction status information

    def success?
      status_code == SUCCESS
    end

    ## Value coercion and retrieval

    def amount_paid
      Money.new(
        amount,
        Money::Currency.find_by_iso_numeric(currency_code)
      )
    end

    ## General data retrieval

    def method_missing(method_name, *args, &block)
      camel = PaymentSense::Utils.camelize(method_name)
      if (options = Utils::RESPONSE_LOOKUP_METHODS[method_name])
        send(options[:method], method_name, options.except(:method))
      elsif @data.keys.include?(camel)
        @data[camel]
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      camel = PaymentSense::Utils.camelize(method_name)
      @data.keys.include?(camel) || super
    end

    def date_time(key, _options = {})
      Time.zone.strptime(@data[key], Utils::ISO_8601_FORMAT)
    end
  end
end

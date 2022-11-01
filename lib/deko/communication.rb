# frozen_string_literal: true

require 'rest-client'
require 'multi_xml'  # Included with httparty, but just in case

module Deko
  class Request
    DEFAULT_FIELDS = {
      'action' => 'credit_application_link',
    }.freeze

    ##
    # Builds a Request instance.
    #
    # ==== Keyword Parameters
    #
    # * +finance+: A Finance instance, detailing the finance option to apply
    #   for.
    # * +goods+: A Goods instance, detailing the products to be paid for,
    #   including delivery.
    # * +identification+: A Identification instance, simply providing a means
    #   to identify the order locally.
    def initialize(finance:, goods:, identification: nil, consumer: nil)
      @finance = finance
      @goods = goods
      @consumer = consumer
      @identification = identification || Identification.new
    end

    def to_params
      params = DEFAULT_FIELDS.dup
      [
        @identification, @finance, @goods, @consumer, @identification
      ].each do |argument|
        next unless argument
        params.merge!(argument.to_params)
      end
      params
    end

    def make_request
      url = if ENV['DEKO_LIVE']
              'https://secure.dekopay.com:6686/'
            else
              'https://test.dekopay.com:3343/'
            end

      proxy_string = ENV['QUOTAGUARDSTATIC_URL']
      RestClient.proxy = proxy_string if proxy_string

      Response.new(RestClient.post(url, to_params))
    end
  end

  class Response
    def initialize(http_response)
      @response = http_response
    end

    def redirection_url
      raise 'Deko returned an error' if error?
      @response.body
    end

    def error_message
      @error_message = begin
                         response = MultiXml.parse(@response.body)
                         response.dig('p4l', 'ERROR')
                       rescue MultiXml::ParseError
                         # Unable to read as XML, so return nil
                         nil
                       end
    end

    def error?
      !!error_message
    end

    def success?
      !redirection_url.empty?
    rescue
      false
    end

    def inspect
      message = if error?
                  "error: '#{error_message}'"
                else
                  "redirection_url: '#{redirection_url}'"
                end
      "#{self.class}(#{message})"
    end
  end

  class FulfilmentRequest < Request
    def initialize(credit_request_id, fulfilment_reference, api_key: nil)
      @credit_request_id = credit_request_id
      @fulfilment_reference = fulfilment_reference
      @api_key = api_key || ENV['DEKO_API_KEY']
    end

    def to_params
      {
        cr_id: @credit_request_id,
        new_state: 'fulfilled',
        fulfilment_ref: @fulfilment_reference,
        api_key: @api_key
      }
    end

    def make_request
      url = if ENV['DEKO_LIVE']
              'https://secure.dekopay.com:6686/'
            else
              'https://test.dekopay.com:3343/'
            end

      proxy_string = ENV['QUOTAGUARDSTATIC_URL']
      RestClient.proxy = proxy_string if proxy_string

      FulfilmentResponse.new(RestClient.post(url, to_params))
    end
  end

  class FulfilmentResponse < Response
    def result
      @result = begin
                  response = MultiXml.parse(@response.body)
                  response.dig('p4l', 'result')
                rescue MultiXml::ParseError
                  # Unable to read as XML, so return nil
                  nil
                end
    end

    def success?
      !error? && result == 'success'
    rescue
      false
    end
  end
end

# frozen_string_literal: true

# Core class for V12 API
class V12Object
  require_relative './v12_application.rb'
  require_relative './v12_customer.rb'
  require_relative './v12_order.rb'
  require_relative './v12_order_line.rb'
  require_relative './v12_retailer.rb'

  attr_reader :retailer

  CONTENT_TYPE = 'application/json'
  BASE_ADDRESS = 'https://apply.v12finance.com'

  def initialize(id, guid, key)
    @retailer = V12Retailer.new(id, guid, key)
  end

  def make_get_request(endpoint)
    endpoint = URI.encode(endpoint)
    http = build_http(BASE_ADDRESS, endpoint)
    http.get(
      endpoint,
      'Content-Type' => CONTENT_TYPE
    )
  end

  def make_post_request(endpoint, request_body)
    body = request_body.tr("'", '\"')
    endpoint = URI.encode(endpoint)
    http = build_http(BASE_ADDRESS, endpoint)
    content_length = request_body.length.to_s
    http.post(
      endpoint,
      body,
      'Content-Type' => CONTENT_TYPE,
      'Content-Length' => content_length
    )
  end

  def make_delete_request(endpoint)
    endpoint = URI.encode(endpoint)
    http = build_http(BASE_ADDRESS, endpoint)
    http.delete(
      endpoint,
      'Content-Type' => CONTENT_TYPE
    )
  end

  def make_patch_request(endpoint, request_body)
    endpoint = URI.encode(endpoint)
    http = build_http(BASE_ADDRESS, endpoint)
    content_length = request_body.length.to_s
    http.patch(
      endpoint,
      request_body,
      'Content-Type' => CONTENT_TYPE,
      'Content-Length' => content_length
    )
  end

  private

  def build_http(_, endpoint)
    full_endpoint = URI("#{BASE_ADDRESS}#{endpoint}")
    http = Net::HTTP.new(full_endpoint.host, full_endpoint.port)
    http.use_ssl = true
    http
  end

  def output_http_error(response)
    log "#{response.code}: #{response.message}"
    log response.message.to_s
  end

  def log(message)
    logger.info message
  end
end

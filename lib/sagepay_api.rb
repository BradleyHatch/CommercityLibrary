# frozen_string_literal: true

##
# A wrapper around the Sagepay REST API.
#
# Official documentation: https://test.sagepay.com/documentation/
class SagepayAPI
  ##
  # Constructs the Sagepay API wrapper with the given values.
  #
  # ==== Parameters
  # * +key+: The API integration key from Sagepay
  # * +password+: The API integration password from Sagepay. This shouldn't be
  #   the account password.
  # * +vendor+: The vendor identifier given by Sagepay.
  # * +opts+: The options hash.
  #
  # ==== Options
  # * +environment+: Controls whether the test or live server is used. Defaults
  #   to TEST. Pass 'LIVE' to use the live server.

  def initialize(key, password, vendor, opts = {})
    @key = key
    @password = password
    @vendor = vendor
    @live = (opts[:environment] == 'LIVE')
    @host = URI.parse("https://pi-#{@live ? 'live' : 'test'}.sagepay.com")
    @http = Net::HTTP.new(@host.host, @host.port).tap { |http| http.use_ssl = true }
  end

  ##
  # Fetches a session key from Sagepay. Used when creating the embedded form.
  def session_key
    response = make_post_request(
      '/api/v1/merchant-session-keys/',
      'vendorName': @vendor
    )
    JSON.parse(response.body)
  end

  ##
  # posting 3dsv1 response back to opayo for confirmation
  def send_fallback_pares(paRes, transactionId)
    response = make_post_request(
      "/api/v1/transactions/#{transactionId}/3d-secure",
      "paRes": paRes
    )
    JSON.parse(response.body)
  end

  ##
  # posting 3dsv2 response back to opayo for confirmation
  def send_challenge_cres(cRes, transactionId)
    response = make_post_request(
      "/api/v1/transactions/#{transactionId}/3d-secure-challenge",
      "cRes": cRes
    )
    JSON.parse(response.body)
  end

  ##
  # 
  def get_transaction(transactionId)
    response = make_get_request("/api/v1/transactions/#{transactionId}")
    JSON.parse(response.body)
  end
  
  ##
  # Attempts to make the transaction with Sagepay.
  #
  # ==== Parameters
  # * +request_object+: A JSON friendly object containing the information and
  #   configuration required to make the transaction. See
  #   https://test.sagepay.com/documentation/#transactions for more
  #   information. See C::PaymentMethod::Sagepay#finalize! for our
  #   implementation.

  def make_transaction(request_object)
    response = make_post_request('/api/v1/transactions/', request_object)
    body = JSON.parse(response.body)

    # byebug

    if response.code != '201' && response.code != "202"
      raise SagepayAPIError.new(body), "Transaction returned #{response.code}"
    end

    status = body['status']

    # byebug

    case status
    when 'Ok'
      body
    when '3DAuth'
      puts "3d auth needed"
      body
    when 'Rejected'
      raise SagepayAPITransactionRejected.new(body), 'Transaction was rejected'
    else
      raise SagepayAPITransactionError.new(body), 'Transaction failed'
    end
  end

  private

  ##
  # A helper method to make a post request. Net::HTTP::Post could/should be
  # replaced by RestClient#post on a rewrite.

  def make_post_request(endpoint, body = {})
    request = Net::HTTP::Post.new(endpoint)
    request.basic_auth(@key, @password)
    request.add_field('Content-Type', 'application/json')
    request.body = body.to_json
    @http.request(request)
  end
  def make_get_request(endpoint, body = {})
    request = Net::HTTP::Get.new(endpoint)
    request.basic_auth(@key, @password)
    request.add_field('Content-Type', 'application/json')
    request.body = body.to_json
    @http.request(request)
  end
end

# Raised when the request returns a non-created response code.
class SagepayAPIError < StandardError
  attr_accessor :body

  def initialize(body)
    @body = body
  end
end

# [Not Used] To be raised when the request fails.
class SagepayAPIRequestError < SagepayAPIError; end

# Raised when the request was valid, but Sagepay doesn't accept the transaction
class SagepayAPITransactionRejected < SagepayAPIError; end

# Raised when the request was invalid.
class SagepayAPITransactionError < SagepayAPIError; end

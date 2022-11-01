# frozen_string_literal: true

class V12Application < V12Object
  STATUS_LOOKUP = {
    0 => :error, 1 => :acknowledged, 2 => :referred, 3 => :declined, 4 => :accepted,
    5 => :awaiting_fulfilment, 6 => :payment_requested, 7 => :payment_processed, 100 => :cancelled
  }.tap { |h| h.default = :error }

  attr_accessor :order
  attr_accessor :customer

  attr_reader :id
  attr_reader :guid
  attr_reader :auth_code
  @status = nil
  # 0 = Error, 1 = Acknowledged, 2 = Referred, 3 = Declined, 4 = Accepted
  # 5 = Awaiting Fulfilment, 6 = Payment Requested, 7 = Payment Processed, 100 = Cancelled
  attr_reader :url
  attr_reader :last_response

  def initialize(params = {})
    raise 'Missing required arguments' unless (@retailer = params[:retailer])
    if params[:order]
      @order = params[:order]
      @customer = params[:customer]
    elsif params[:id]
      @id = params[:id]
      update
    else
      raise 'Missing required arguments'
    end
  end

  def send
    body = to_json
    response = make_post_request('/latest/retailerapi/SubmitApplication', body)
    update_from(response)
  end

  def update
    body = {
      'ApplicationId': @id,
      'IncludeExtraDetails': false,
      'IncludeFinancials': false,
      'Retailer': @retailer.to_hash
    }.to_json
    response = make_post_request('/latest/retailerapi/CheckApplicationStatus', body)
    update_from(response)
  end

  def cancel
    body = {
      'ApplicationId': @id,
      'Retailer': @retailer.to_hash,
      'Update': '100'
    }.to_json
    response = make_post_request('/latest/retailerapi/UpdateApplication', body)
    update_from(response)
  end

  def request_payment
    body = {
      'ApplicationId': @id,
      'Retailer': @retailer.to_hash,
      'Update': '40'
    }.to_json
    response = make_post_request('/latest/retailerapi/UpdateApplication', body)
    update_from(response)
  end

  # This is confusing to read because it's been broken into tiny pieces
  # But it made Rubocop happy
  def update_from(response)
    response_parsed = (JSON.parse response.body)
    @last_response = response_parsed
    # If attempting to operate on a cancelled application, perform a fresh request for status
    return update if response_parsed['Errors'].size == 1 && response_parsed['Errors'][0]['Code'] == 'UPA007'
    evaluate_response(response, response_parsed)
  end

  def evaluate_response(response, response_parsed)
    if response.code == '200' && response_parsed['Status'] != 0
      assign_attrs(response_parsed)
      true
    else
      @status = :error
      false
    end
  end

  def assign_attrs(response_parsed)
    @id = response_parsed['ApplicationId']
    @guid = response_parsed['ApplicationGuid']
    @auth_code = response_parsed['AuthorisationCode']
    @status = STATUS_LOOKUP[response_parsed['Status']]
    @url = response_parsed['ApplicationFormUrl']
  end

  def status
    update
    @status
  end

  def to_hash
    result = {
      'Retailer': @retailer.to_hash,
      'Order': @order&.to_hash
    }
    result['Customer'] = @customer.to_hash if customer
    result
  end
end

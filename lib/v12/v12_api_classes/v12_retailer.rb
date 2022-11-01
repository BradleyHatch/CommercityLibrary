# frozen_string_literal: true

class V12Retailer < V12Object
  attr_reader :id
  attr_reader :guid
  attr_reader :key

  def initialize(id, guid, key)
    @id = id
    @guid = guid
    @key = key
  end

  def to_hash
    {
      'AuthenticationKey': @key,
      'RetailerGuid': @guid,
      'RetailerId': @id
    }
  end
end

# frozen_string_literal: true

module Deko
  class CreditStatusNotification
    def initialize(data)
      @data = data
    end

    def unique_reference
      @data.dig('Identification', 'RetailerUniqueRef')
    end

    def api_key
      @data.dig('Identification', 'api_key')
    end

    def api_key_matches?
      api_key == ENV['DEKO_API_KEY']
    end

    def deko_id
      @data['CreditRequestID']
    end

    def status
      @data['Status'].downcase.to_sym
    end
  end
end

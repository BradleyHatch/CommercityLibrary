# frozen_string_literal: true


module EbaySession
  extend ActiveSupport::Concern

  def get_session_id
    request = EbayTrader::Request.new('GetSessionID') do
      ErrorLanguage 'en_GB'
      WarningLevel 'High'
      DetailLevel 'ReturnAll'
      RuName ENV['EBAY_RU_NAME']
    end
    request.response_hash
  end

  def fetch_token(session_id)
    request = EbayTrader::Request.new('FetchToken') do
      ErrorLanguage 'en_GB'
      WarningLevel 'High'
      DetailLevel 'ReturnAll'
      SessionID session_id
    end

    request.response_hash
  end
  
end

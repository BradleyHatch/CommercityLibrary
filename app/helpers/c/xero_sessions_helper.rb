# frozen_string_literal: true

module C
  module XeroSessionsHelper
    def xero_client
      raise 'Xero not enabled' unless C.xero_enabled
      @xero_client ||= Xeroizer::PublicApplication.new(
        ENV['XERO_OAUTH_KEY'], ENV['XERO_OAUTH_SECRET']
      )
      if (xero_access = session[:xero_access])
        @xero_client.authorize_from_access(xero_access['token'],
                                           xero_access['key'])
      end
      @xero_client
    end
  end
end

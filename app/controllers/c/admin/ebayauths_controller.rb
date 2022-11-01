# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class EbayauthsController < AdminController
      load_and_authorize_resource class: C::Ebayauth

      def index
        if params.key?("success")
          @success = params["success"].to_s == "true"  
        end
        if params.key?("error")
          @error = params["error"]
        end
      end

      def new_auth
        response = C::EbayJob.perform_now('get_session_id')
        session_id = response['session_id']

        url = "https://signin.ebay.com/ws/eBayISAPI.dll?SignIn"

        is_sandbox = ENV['EBAY_ENVIRONMENT'] == "sandbox"

        if is_sandbox
          url = "https://signin.sandbox.ebay.com/ws/eBayISAPI.dll?SignIn"
        end

        url += "&runame=#{ENV['EBAY_RU_NAME']}"

        if session_id.present?
          session[:ebay_session_id] = session_id

          url += "&SessID=#{session_id}"
          redirect_to url
        else
          redirect_to ebayauths_path(success: false, error: "No session id")
        end
      end

      def success
        session_id = session[:ebay_session_id]

        response = C::EbayJob.perform_now('fetch_token', session_id)

        if response["ebay_auth_token"].present?
          C::Ebayauth.create(
            token: response["ebay_auth_token"],
            expires_at: response["hard_expiration_time"].to_datetime,
          )
          redirect_to ebayauths_path(success: true)
        else 
          puts response
          redirect_to ebayauths_path(success: false, error: "Bad params")
        end
      end

      def fail
        redirect_to ebayauths_path(success: false, error: "Declined confirmation")
      end
    end
  end
end

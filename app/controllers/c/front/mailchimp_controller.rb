# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Front
    class MailchimpController < ApplicationController
      def subscribe
        require 'mailchimp'
        begin
          @mc = ::Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
          email = params['email']
          begin
            @mc.lists.subscribe(ENV['MAILCHIMP_LIST_ID'], 'email' => email)
            flash[:success] = "#{email} subscribed successfully"
          rescue ::Mailchimp::ListAlreadySubscribedError
            flash[:error] = "#{email} is already subscribed to the list"
          rescue ::Mailchimp::ListDoesNotExistError
            flash[:error] = 'The list could not be found'
            redirect_back(fallback_location: front_end_root_path)
            return
          rescue ::Mailchimp::Error => ex
            flash[:error] = if ex.message
                              ex.message
                            else
                              'An unknown error occurred'
                            end
          end
        rescue ::Mailchimp::InvalidApiKeyError => ex
          flash[:error] = ex.message
        end
        redirect_back(fallback_location: front_end_root_path)
      end
    end
  end
end

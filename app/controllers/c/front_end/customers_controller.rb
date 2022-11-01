# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class CustomersController < MainApplicationController

      CONSENT_KEYS = %w[
        consent_order
        consent_promotion
        consent_products
        consent_contact_post
        consent_contact_phone
        consent_contact_email
      ]

      def get_consent
        @email = params[:email]
        @content = C::Content.find_by(slug: :consent)
      end

      def save_consent
        @email = params[:email]
        @data = params.select { |k, v| CONSENT_KEYS.include?(k) }
        @data.permit!
        @data.each { |k, v| @data[k] = ActiveModel::Type::Boolean.new.cast(v) }
        update_customer(@email, @data)
        C::EnquiriesMailer.new_consent(@email, @data).deliver_now
        redirect_to '/thanks'
      end

      def get_unsubscribe
        @email = params[:email]
      end

      def save_unsubscribe
        @email = params[:email]
        if customer = C::Customer.find_by(email: @email)
          customer.account.present? ? customer.account.destroy : customer.destroy
        end
        if account = C::CustomerAccount.find_by(email: @email)
          account.destroy
        end
        redirect_to '/thanks'
      end

      def update_customer(email, data)
        @customer = C::Customer.find_by(email: email)
        return if @customer.blank? || data.blank?
        @customer.update(data)
      end

    end
  end
end

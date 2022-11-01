# frozen_string_literal: true

require 'money'

module Ebay
  class Order
    attr_reader :order

    def initialize(order_hash)
      @order = order_hash
    end

    def hash
      @order
    end

    # # # # #

    # meta data stuff
    def order_id
      @order[:order_id]
    end

    def created
      @order[:created_time]
    end

    def buyer_id
      @order[:buyer_user_id]
    end

    def checkout_message
      @order[:buyer_checkout_message]
    end

    # order item / transaction stuff
    def order_items
      @order[:transaction_array][:transaction]
    end

    # checking if order_items is hash and returning first order item
    def first_item
      if order_items.class.to_s == 'ActiveSupport::HashWithIndifferentAccess'
        [order_items].first
      else
        order_items.first
      end
    end

    # methods all depending on first_item
    def first_item_shipping
      first_item[:shipping_details]
    end

    def first_item_tracking
      first_item_shipping[:shipment_tracking_details]
    end

    def first_item_tracking_number
      first_item_tracking[:shipment_tracking_number]
    end

    def first_item_carrier
      first_item_tracking[:shipping_carrier_used]
    end

    def tracking_details_present?
      first_item && first_item_shipping && first_item_tracking
    end

    def first_item_buyer
      first_item[:buyer]
    end

    def first_item_buyer_email
      first_item_buyer[:email]
    end

    def first_item_buyer_name
      "#{first_item_buyer[:user_first_name]} #{first_item_buyer[:user_last_name]}"
    end

    def first_item_gateway
      first_item[:external_transaction]
    end

    # alt methods for returning external gateway transaction id
    def monetary_details
      if @order[:monetary_details]
        @order[:monetary_details]
      else 
        {}
      end
    end

    def payments
      if monetary_details[:payments] && monetary_details[:payments][:payment]
        Array.wrap(monetary_details[:payments][:payment])
      else
        []
      end
    end

    def payments_for_store
      payments.select { |p| p[:payee_type] == "eBayUser" }
    end

    def payments_not_for_store
      payments.select { |p| p[:payee_type] != "eBayUser" }
    end

    def monetary_external_id
      payment = payments_for_store.first
      if payment && payment[:reference_id_type] == 'ExternalTransactionID'
        payment[:reference_id]
      end
    end

    # payment stuff
    def amount_paid
      if C.ebay_ignore_gsp_fees && payments_not_for_store.length > 0
        payments_for_store.map { |p| p[:payment_amount] }.reduce(:+)
      else
        @order[:amount_paid]
      end
    end

    # this is NOT the shipping service buyer paid for buy container for services
    # offered in the listing
    def shipping_details
      @order[:shipping_details]
    end

    def sales_tax_percent
      shipping_details[:sales_tax][:sales_tax_percent]
    end

    def sales_tax_amount
      shipping_details[:sales_tax][:sales_tax_amount]
    end

    def sales_record_number
      shipping_details[:selling_manager_sales_record_number]
    end

    # address stuff
    def valid_address?
      !address[:name].blank? && !address[:street1].blank? && !address[:city_name].blank? && !address[:country_name].blank?
    end

    def address
      @order[:shipping_address]
    end

    def phone
      address[:phone]
    end

    # shipping service that buyer has paid for
    def shipping
      @order[:shipping_service_selected]
    end

    def shipping_cost
      if C.ebay_ignore_gsp_fees && payments_not_for_store.length > 0
        Money.new(0)
      else
        shipping[:shipping_service_cost]
      end
    end

    def shipping_service
      shipping[:shipping_service]
    end

    # order status stuff
    def paid_time
      @order['paid_time']
    end

    def shipped_time
      @order['shipped_time']
    end

    def status
      @order['order_status']
    end

    def cancel_status
      @order['cancel_status']
    end

    def cancel_pending?
      if cancel_status
        cancel_status == 'CancelPending'
      end
    end

    def cancelled?
      if cancel_status
        cancel_status == 'CancelComplete' ||
        cancel_status == 'CancelClosedWithRefund' ||
        cancel_status == 'CancelClosedUnknownRefund'
      end
    end

  end
end

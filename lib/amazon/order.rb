# frozen_string_literal: true

module Amazon
  class Order
    def initialize(order_hash)
      @order_hash = order_hash
    end

    def id
      @order_hash['AmazonOrderId']
    end

    def total
      parse_money(@order_hash['OrderTotal'])
    end

    def status
      case @order_hash['OrderStatus']
      when 'Canceled'
        :cancelled
      when 'Shipped'
        :dispatched
      else
        # Includes 'Unshipped' implicitly
        :awaiting_dispatch
      end
    end

    def purchase_date
      parse_date_time(@order_hash['PurchaseDate'])
    end

    def earliest_delivery_date
      parse_date_time(@order_hash['EarliestDeliveryDate'])
    end

    def latest_delivery_date
      parse_date_time(@order_hash['LatestDeliveryDate'])
    end

    def buyer_name
      @order_hash['BuyerName']
    end

    def buyer_email
      @order_hash['BuyerEmail']
    end

    def buyer_phone
      @order_hash['ShippingAddress']['Phone']
    rescue NoMethodError
      nil
    end

    def shipping_level
      @order_hash['ShipServiceLevel']
    end

    def cancelled?
      status == :cancelled
    end

    def dispatched?
      status == :dispatched
    end

    def awaiting_dispatch?
      status == :awaiting_dispatch
    end

    def source_hash
      @order_hash
    end

    def parse_money(element)
      Money.from_amount(element['Amount'].to_f, element['CurrencyCode'])
    end

    def tax_details
      @order_hash['TaxRegistrationDetails']
    end

    def vat_registered?
      tax_details.present? && 
      tax_details["member"].present? && 
      tax_details["member"]["taxRegistrationType"] === "VAT" &&
      source_hash['ShippingAddress'].present? &&
      C::Country.find_by(iso2: source_hash['ShippingAddress']['CountryCode']).present? &&
      C::Country.find_by(iso2: source_hash['ShippingAddress']['CountryCode']).iso2 != "GB"
    end

    private

    def parse_date_time(dt)
      begin
        return DateTime.parse(dt).in_time_zone
      rescue => e
        puts dt
        puts e
        return nil
      end
    end
  end
end

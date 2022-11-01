# frozen_string_literal: true

require 'money'

module Amazon
  class Item
    attr_writer :product

    # Methods may look sparse and easy to make abstract, but they are
    # placeholders for more logic to be moved in later.
    def initialize(order_item_response)
      @order_item_hash = order_item_response
    end

    def name
      @order_item_hash['Title'].dup.force_encoding('UTF-8')
    end

    def sku
      @order_item_hash['SellerSKU']
    end

    def quantity
      @order_item_hash['QuantityOrdered'].to_i
    end

    def price
      parse_money(@order_item_hash['ItemPrice']) / quantity
    end

    def shipping
      parse_money(@order_item_hash['ShippingPrice'] || { 'Amount': 0}) / quantity
    end

    def product
      @product ||= C::Product::Variant.find_by(sku: @order_item_hash['SellerSKU'])
    end

    def source_hash
      @order_item_hash
    end

    def tax_rate
      if product
        product.master.tax_rate
      else
        0.2
      end
    end

    def parse_money(element)
      Money.from_amount(element['Amount'].to_f, element['CurrencyCode'])
    end
  end
end

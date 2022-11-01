# frozen_string_literal: true

module C
  module Order
    class Item < ApplicationRecord
      belongs_to :order, class_name: 'C::Order::Sale'
      belongs_to :product, class_name: 'C::Product::Variant', optional: true
      belongs_to :voucher, class_name: 'C::Product::Voucher', optional: true
      belongs_to :cart_item, class_name: 'C::CartItem', optional: true

      validates :quantity,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }
      validates :name, :sku, :tax_rate, :price, presence: true

      monetize :price_pennies

      scope :products, (-> { where.not(product_id: nil) })
      scope :vouchers, (-> { where.not(voucher_id: nil) })

      def product
        super || C::Product::Variant.find_by(sku: sku.delete(' '))
      end

      def tax
        (price / (1 + (tax_rate / 100))) * (tax_rate / 100)
      end

      def price_without_tax
        price - tax
      end

      def price_pennies_without_tax
        price_without_tax.fractional
      end

      def total_tax
        tax * quantity
      end

      def total_price
        price * quantity
      end

      def total_price_without_tax
        price_without_tax * quantity
      end

      def ebay_order?
        order.ebay?
      end

      def manual_order?
        order.manual?
      end

      def price_pennies_no_vat
        price_pennies / 1.2
      end

      # Tax rate should always return zero if the order is not liable for tax.
      # Otherwise, it should return the original value.
      def tax_rate
        return nil if super.nil?
        if order.blank?
          super
        else
          order.tax_liable? ? super : 0
        end
      end

      # Grabbing eBay item_id for an order item from the line item id
      def ebay_item_id
        ebay_order_line_item_id.split('-')[0] if ebay_order_line_item_id.present?
      end

      def ebay_sku
        self[:ebay_sku].blank? ? sku : self[:ebay_sku]
      end

      def process
        return unless product
        if product.current_stock > 0
          update_listing_quantity
        elsif C.delist_when_zero
          delist_when_zero
        else
          update_listing_quantity
        end
      end

      # Updating product updated_at time to get picked up by periodic stock job
      def update_listing_quantity
        update(updated_at: Time.now)
        product.update(updated_at: Time.now)
      end

      # This does nothing for safety reasons, override it with a decorator for
      # delisting power
      def delist_when_zero
        return unless C.delist_when_zero
      end
    end
  end
end

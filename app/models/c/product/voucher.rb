# frozen_string_literal: true

module C
  module Product
    class Voucher < ApplicationRecord
      has_many :variant_vouchers, dependent: :destroy
      has_many :variants, through: :variant_vouchers
      
      has_many :brand_vouchers, dependent: :destroy
      has_many :brands, through: :brand_vouchers

      has_many :category_vouchers, dependent: :destroy
      has_many :categories, through: :category_vouchers

      has_many :cart_items
      has_many :order_items, class_name: 'C::Order::Item', dependent: :nullify
      has_many :orders, class_name: 'C::Order::Sale', through: :order_items

      accepts_nested_attributes_for :variant_vouchers, allow_destroy: true
      accepts_nested_attributes_for :brand_vouchers, allow_destroy: true
      accepts_nested_attributes_for :category_vouchers, allow_destroy: true

      monetize :flat_discount_pennies
      monetize :per_item_discount_pennies
      monetize :minimum_cart_value_pennies

      validates :name, presence: true
      validates :code, presence: true, uniqueness: true

      scope :ordered, (-> { order(code: :asc) })

      def discount_for_cart(cart)
        cart_discount = Money.new(0)
        return cart_discount unless valid_for_cart?(cart)

        valid_cart_items = valid_items_for_cart(cart)
        cart_total = valid_cart_items.map(&:price).sum
        total_valid_items = valid_cart_items.map(&:quantity).sum
        cart_discount = per_item_discount * total_valid_items

        per_item_mul = cart_total * (1 - per_item_discount_multiplier)

        (cart_total * (1 - discount_multiplier)) + cart_discount + flat_discount + per_item_mul
      end

      def price_for_cart(cart)
        Money.new(0) - discount_for_cart(cart)
      end

      def active?
        active &&
          (start_time.nil? || start_time < Time.now) &&
          (end_time.nil? || Time.now < end_time)
      end

      def has_uses_left?
        return true if uses < 1
        return uses > times_used
      end

      def valid_for_cart?(cart)
        return false unless active?

        # if it has no uses left and it isn't attached to this cart, return false
        return false if !has_uses_left? && !cart.cart_items.pluck(:voucher_id).compact.include?(self.id)

        if (restricted_brand && restricted) || (restricted_category && restricted)
          valid_items = valid_items_for_cart(cart)

          return false unless valid_items.any?
          return false unless variants & cart.cart_items.variants.map(&:variant) == variants

          relevant_subtotal = valid_items.map(&:price).sum
          relevant_subtotal >= minimum_cart_value
        else
          cart.item_subtotal_excluding_vouchers >= minimum_cart_value &&
            (!restricted || valid_items_for_cart(cart).any?) &&
            (!restricted_brand || valid_items_for_cart(cart).any?) &&
            (!restricted_category || valid_items_for_cart(cart).any?) 
        end
      end

      def already_in_cart?(cart)
        cart.cart_items.pluck(:voucher_id).include?(id)
      end

      def valid_items_for_cart(cart)
        items = cart.cart_items.variants.joins(variant: [:master])

        # if we are restricted by brand, filter the set of cart items by master.brand
        if restricted_brand
          items = items.where(c_product_masters: { brand_id: brands.pluck(:id) })
        end

        # if we are restricted by category, filter the set of cart items by master.categorizations
        # note: this does self_and_descendants
        if restricted_category
          category_ids = categories.map { |category| category.self_and_descendants.pluck(:id) }.flatten
          masters = C::Product::Master.joins(:categorizations).where(c_product_categorizations: { category_id: category_ids })
          items = items.where(c_product_masters: { id: masters.pluck(:id) })
        end

        if restricted
          # if we are restricted and we have filtered by brand/category, blacklist the restricted products
          # i don't understand this behaviour but it was here bfore so i left it
          if restricted_brand || restricted_category
            items = items.where.not(variant_id: variants.pluck(:id))
          # else whitelist the restricted variants
          else
            items = items.where(variant_id: variants.pluck(:id))
          end
        end
          
        items
      end

      def breakdown
        result = []
        if restricted || restricted_brand || restricted_category
          result << "#{((1 - discount_multiplier) * 100).to_i}% off applicable item total" if discount_multiplier != 1
          result << "#{humanized_money_with_symbol per_item_discount} off per applicable item" if per_item_discount != 0
          result << "#{((1 - per_item_discount_multiplier) * 100).to_i}% off per applicable item" if per_item_discount_multiplier != 0
          result << "#{humanized_money_with_symbol flat_discount} off applicable item total" if flat_discount_pennies != 0
        else
          result << "#{((1 - discount_multiplier) * 100).to_i}% off order total" if discount_multiplier != 1
          result << "#{humanized_money_with_symbol per_item_discount} off per item" if per_item_discount != 0
          result << "#{((1 - per_item_discount_multiplier) * 100).to_i}% off per item" if per_item_discount_multiplier != 0 && per_item_discount_multiplier != 1
          result << "#{humanized_money_with_symbol flat_discount} off order total" if flat_discount_pennies != 0
        end
        result.to_sentence
      end

      INDEX_TABLE = {
        'Code': {
          link: {
            name: { call: 'code' },
            options: '[:edit, object]'
          }
        },
        'Name': { call: 'name' },
        'Active?': { call: 'active?' }
      }.freeze

      private

      def humanized_money_with_symbol(money)
        ActionController::Base.helpers.humanized_money_with_symbol(money)
      end
    end
  end
end

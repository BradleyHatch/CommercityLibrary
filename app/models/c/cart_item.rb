# frozen_string_literal: true

module C
  class CartItem < ApplicationRecord
    belongs_to :cart
    belongs_to :variant, class_name: 'C::Product::Variant'
    belongs_to :voucher, class_name: 'C::Product::Voucher'

    has_many :cart_item_notes, class_name: 'C::CartItemNote', dependent: :destroy
    has_many :cart_item_option_variants, class_name: 'C::CartItemOptionVariant', dependent: :destroy
    has_many :option_variants, through: :cart_item_option_variants, class_name: 'C::Product::OptionVariant'
    has_many :options, through: :option_variants, class_name: 'C::Product::Option'

    has_one :order_item, class_name: 'C::Order::Item'

    validates :cart, presence: true
    validates :variant, presence: true, unless: :voucher
    validates :voucher, presence: true, unless: :variant
    validates :quantity,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :variants, -> { where.not(variant_id: nil) }
    scope :vouchers, -> { where.not(voucher_id: nil) }

    # delete self if quantity is 0
    after_save do
      destroy if quantity < 1
    end

    around_destroy do |item, block|
      # Destroy Cart if not cart items
      @cart = item.cart
      block.call
      if @cart
        @cart.destroy if @cart.empty?
      else
        ActionMailer::Base.mail(
          from: C.errors_email,
          to: C.errors_email,
          subject: "#{C.store_name} cart item with no cart",
          body: "Cart Item ID: #{item.id}"
        ).deliver
      end
    end

    def price_in_pence
      unit_price_in_pence * quantity
    end

    def price
      unit_price * quantity
    end

    def price_without_tax
      price - tax
    end

    def unit_price_in_pence
      unit_price.fractional
    end

    def unit_price
      return voucher.price_for_cart(cart) if voucher
      price = variant.price(channel: :web, tax: cart.tax_liable? ? true : false)
      cart_item_option_variants.inject(price) do |acc, cart_item_option_variant|
        acc + cart_item_option_variant.price.send(cart.tax_liable? ? 'with_tax' : 'without_tax')
      end
    end

    def unit_price_without_tax
      unit_price - unit_tax
    end

    def tax
      unit_tax * quantity
    end

    def unit_tax
      return 0 if voucher || !cart.tax_liable?
      price = variant.tax(channel: :web)
      cart_item_option_variants.inject(price) do |acc, cart_item_option_variant|
        acc + cart_item_option_variant.price.tax
      end
    end

    def quantity
      super || 0
    end

    def chosen_quantity_out_of_stock?
      quantity > variant.current_stock
    end

    # Expects a set of Product::OptionVariant ids, optionally takes a quantity n
    # Adjusts the option_variants of n items to match the given set
    # CartItems may only have one option_variants set, so a new item may be created

    # Eg. Operating on an item with quantity = 5 and option_variants = []
    #     Given args: (option_variants = [1], n = 2)
    #     - Duplicates the item
    #     - Updates the old item with quantity = 3
    #     - Updates the new item with quantity = 2, option_variants = [1]

    def update_option_variants(ids, n=nil)
      ids = ids.sort
      n ||= quantity

      new_item = cart.find_item_with_option_variants(variant_id, ids)
      if new_item
        new_item.update!(quantity: new_item.quantity + n)
      else
        new_item = cart.cart_items.create!(variant: variant, quantity: n)
        new_item.update(option_variant_ids: ids)
      end
      update!(quantity: quantity - n)

      new_item
    end

    def name
      variant ? variant.name : voucher.name
    end

    def description
      variant ? variant.description || variant.sku : voucher.name
    end

    def sku
      variant ? variant.sku : voucher.code
    end
  end
end

# frozen_string_literal: true

module C
  class Cart < ApplicationRecord
    belongs_to :customer
    has_many :cart_items, autosave: true, dependent: :destroy
    belongs_to :order, class_name: 'C::Order::Sale'
    has_one :shipping_address, through: :order, class_name: 'C::Address',
                               autosave: true
    has_one :billing_address, through: :order, class_name: 'C::Address',
                              autosave: true
    has_one :delivery, through: :order, class_name: 'C::Order::Delivery',
                       autosave: true
    has_one :payment, through: :order, class_name: 'C::Order::Payment',
                      autosave: true

    accepts_nested_attributes_for :order
    accepts_nested_attributes_for :shipping_address
    accepts_nested_attributes_for :billing_address
    accepts_nested_attributes_for :delivery
    accepts_nested_attributes_for :cart_items

    scope :not_completed, -> { where(id: C::Order::Sale.carts.joins(:cart).select('c_carts.id')) }
    scope :not_completed_three_days, -> { not_completed.where('updated_at < ?', Time.current - 3.days)}
    scope :not_completed_five_days, -> { not_completed.where('updated_at < ?', Time.current - 5.days)}
    scope :not_completed_seven_days, -> { not_completed.where('updated_at < ?', Time.current - 7.days)}

    def cart_items_count
      "Basket (#{cart_items.count})"
    end

    def variants
      C::Product::Variant.where(id: cart_items.where(voucher_id: nil).pluck(:variant_id))
    end

    def variant_services
      C::Delivery::Service.where(id: variants.left_joins(:service_variants).group(:id).pluck('array_agg(service_id)').reduce(&:&))
    end

    def add_item(item, quantity=1, option_ids = [])
      item = C::Product::Variant.find(item[:variant_id])
      option_variant_ids = item.options.where(id: option_ids).pluck('c_product_option_variants.id')
      existing_cart_item = find_item_with_option_variants(item.id, option_variant_ids)
      if existing_cart_item
        existing_cart_item.update(quantity: existing_cart_item.quantity + quantity.to_i)
        save!
      else
        new_item = cart_items.build(cart: self, variant: item, quantity: quantity.to_i)
        save!
        new_item.update(option_variant_ids: option_variant_ids)
      end
    end

    def add_voucher(voucher)
      return false unless !has_voucher? && !voucher.already_in_cart?(self) && voucher.valid_for_cart?(self)
      new_item = cart_items.build(cart: self, voucher: voucher, quantity: 1)
      voucher.update!(times_used: voucher.times_used + 1)
      new_item.save!
      true
    end

    def has_voucher?
      cart_items.where.not(voucher_id: nil).any?
    end

    def voucher
      cart_items.where.not(voucher_id: nil).first
    end

    def remove_item(item_id)
      cart_items.find(item_id).destroy if cart_item_ids.include? item_id
    end

    def include?(variant)
      cart_items.find_by(variant: variant).present?
    end

    def total_items
      cart_items.pluck(:quantity).inject(:+) || 0
    end

    def item_subtotal
      cart_items.map(&:price).sum
    end

    def item_subtotal_without_tax
      result = item_subtotal - tax
      if delivery
        result + delivery.tax
      else
        result
      end
    end

    def item_subtotal_excluding_vouchers
      cart_items.variants.map(&:price).sum
    end

    def tax
      result = cart_items.map(&:tax).sum
      if delivery
        result += delivery.tax
      end
      return result if result.zero? || !has_voucher?
      result + (voucher.price - voucher.price/1.2)
    end

    def tax_liable?
      if order.blank?
        true
      else
        order.tax_liable?
      end
    end

    def price
      Money.new(item_subtotal + delivery_price)
    end

    def total_weight
      total = 0
      cart_items.each do |item|
        total += (item.variant&.weight || 0) * item.quantity
      end
      total
    end

    def delivery_price
      (delivery&.price || 0)
    end

    def first_variant
      cart_items.blank? ? nil : cart_items.first.variant
    end

    def first_cart_item_category
      if first_variant.nil?
        nil
      else
        first_variant.categories.first
      end
    end

    def latest_item
      cart_items.order(created_at: :desc).first
    end

    def has_delivery_override?
      cart_items.each do |item|
        return true if item.variant&.has_delivery_override?
      end
      false
    end

    def delivery_override
      cart_items.map do |item|
        item.variant.delivery_override if item.variant&.has_delivery_override?
      end.compact.sum
    end

    def copy_items_to_order
      order.items.destroy_all
      cart_items.each do |cart_item|
        if cart_item.voucher
          order.items.create(voucher_id: cart_item.voucher_id,
                             name: cart_item.voucher.name,
                             sku: cart_item.voucher.code,
                             price: cart_item.unit_price,
                             tax_rate: 0,
                             quantity: 1,
                             cart_item_id: cart_item.id,
                            )
        else
          description = cart_item.options.any? ? 'with ' + cart_item.options.pluck(:name).to_a.to_sentence : ''
          tax_rate = cart_item.variant.tax_rate(channel: :web)
          order.items.create(product_id: cart_item.variant_id,
                             name: cart_item.variant&.name,
                             description: description,
                             sku: cart_item.variant&.sku,
                             price: cart_item.unit_price,
                             tax_rate: tax_rate,
                             quantity: cart_item.quantity,
                             gift_wrapping: cart_item.gift_wrapping,
                             cart_item_id: cart_item.id,
                            )
         end
      end
    end

    def items_need_updating?
      digest = Digest::SHA1.hexdigest(
        # '[[:id, :quantity, "option1, option2, ..."], ... ]'
        cart_items.left_joins(:options).group(:id).order(
          variant_id: :asc
        ).pluck(
          :variant_id,
          :quantity,
          :gift_wrapping,
          # ::text is postgres type conversion
          # string_agg is a postgres string concatination function
          "string_agg(c_product_options.id::text, ', ')"
        ).to_s
      )
      return false unless item_digest.blank? || item_digest != digest
      payment&.cancel!
      payment&.destroy
      order.payment = nil
      update(item_digest: digest)
      true
    end

    # If the shipping address country has changed or hasn't been set, force new copy of order items
    def check_country
      order_billing_address = order&.billing_address_with_fallback
      if order_billing_address && (previous_country_id.blank? || previous_country_id != order_billing_address.country_id)
        update({ item_digest: nil, previous_country_id: order_billing_address.country_id })
      end
    end

    def integrity_check
      return unless items_need_updating?
      copy_items_to_order
      return unless has_delivery?
      delivery.calculated_price = calculate_delivery_price.with_tax
      delivery.save!
    end

    def calculate_delivery_price
      if C.combined_delivery_rate
        order.delivery.delivery_service.price_for_cart_total_and_zone(
          price.fractional,
          shipping_address.country.zone
        )
      elsif C.flat_delivery_rate
        order.delivery.delivery_service.price_for_cart_total(
          price.fractional
        )
      else
        order.delivery.delivery_service.price(
          total_weight,
          shipping_address.country.zone
        )
      end
    end

    def valid_for_price?
      order.delivery
           .valid_for_cart_amount?(price, shipping_address.country.zone)
    end

    def contains_out_of_stock_items?
      items = order ? order.items : cart_items
      call = order ? 'product' : 'variant'
      items.any? do |item|
        next if ((item.respond_to? :voucher) && item.voucher) || item.send(call).nil?
        item.quantity > item.send(call).current_stock
      end
    end

    def empty?
      cart_items.variants.empty?
    end

    #####################################
    # ############CHECKOUT################
    #####################################

    def begin_checkout
      return if checkout_started?
      create_order(customer_id: customer_id, channel: :web)
      save!
    end

    def checkout_started?
      order.present?
    end

    def destroy_payment!
      return if payment.nil?
      payment.cancel!
      payment.destroy
    end

    def destroy_address!
      return if shipping_address.nil?
      shipping_address.destroy
    end

    def destroy_delivery!
      return if delivery.nil?
      delivery.destroy
    end

    def cancel_checkout
      self.customer_id = nil
      self.shipping_address_id = nil
      self.delivery_id = nil
      self.payment_id = nil
      save!
    end

    def stage
      return :account unless has_customer? || anonymous
      return :address unless has_shipping_address?
      return :delivery unless has_delivery?
      return :payment unless payment?
      :final
    end

    def has_customer?
      order.present? && order.customer.present?
    end

    def has_shipping_address?
      shipping_address.present?
    end

    def has_delivery?
      delivery.present?
    end

    def payment?
      payment.present? && (payment.amount_paid.positive? ||
                           payment.payable_type == 'C::PaymentMethod::Credit')
    end

    def build_payment?
      payment || order.build_payment
    end

    def build_customer?
      customer || order.build_customer
    end

    def build_shipping_address?
      shipping_address || order.build_shipping_address
    end

    def build_billing_address?
      billing_address || order.build_billing_address
    end

    def build_payment_fields
      build_billing_address?
      build_customer?
      build_payment?
    end

    def build_overridden_delivery
      order.build_delivery(
        name: 'Custom delivery',
        price: delivery_override,
        overridden: true
      )
    end

    def build_selected_delivery(params)
      order.build_delivery(params)
      delivery = order.delivery
      delivery.temp_sale = order
      delivery.calculated_price = calculate_delivery_price.with_tax
      delivery
    end

    def finalize!(user_params = {})
      order_valid = order.valid?
      
      payment_finalize = payment.finalize!(user_params)

      if !order_valid || !payment_finalize
        return false
      end

      if payment_finalize.is_a?(Hash)        
        status = payment_finalize['status']

        if status == "3DAuth"
          if payment_finalize['acsUrl'].present? && payment_finalize['paReq'].present?
            return {
              "type" => "SagePay3dF",
              "acsUrl" => payment_finalize['acsUrl'],
              "paReq" => payment_finalize['paReq'],
              "transactionId" => payment_finalize['transactionId'],
            }
          end
          if payment_finalize['acsUrl'].present? && payment_finalize['cReq'].present?
            return {
              "type" => "SagePay3dC",
              "acsUrl" => payment_finalize['acsUrl'],
              "cReq" => payment_finalize['cReq'],
              "transactionId" => payment_finalize['transactionId'],
            }
          end
        end
        if status != "Ok"
          raise 'payment returned a hash but nothing is setup to handled it'
        end
      end
      
      order.update(
        recieved_at: Time.zone.now,
        status: payment.paid? ? :awaiting_dispatch : :awaiting_payment
      )
      order.decrement_items
      order.process
      order.send_order_notifications
      destroy
    end

    def finance_eligible?
      price.to_i * 0.9 > 250
    end

    def minimum_monthly_finance
      price * 0.9 / 6
    end

    def generate_customer_from_address_details
      return unless order.customer.present? && order.customer.name.blank?
      order.customer.update(name: shipping_address.name)
    end

    def find_item_with_option_variants(variant_id, ids, options = { not: [] })
      cart_items.where(variant_id: variant_id).where.not(id: options[:not]).find_each do |item|
        return item if item.option_variants.order(:id).pluck(:id) == ids
      end
      nil
    end

    def combine_duplicate_items
      cart_items.where.not(variant_id: nil).each do |item|
        if
              cart_items.find_by(id: item.id) &&
              item.variant.options.any? &&
              (duplicate = find_item_with_option_variants(item.variant_id, item.option_variant_ids, not: item.id))

          item.update(quantity: item.quantity + duplicate.quantity)
          duplicate.destroy!
        end
      end
    end

    def copy_contact_details_to_order
      attrs = order.customer.as_json(only: %i[name email phone mobile])
      order.update(attrs&.symbolize_keys)
    end

    def generate_abandoned_voucher
      start_time = Time.now + 1.weeks
      end_time = start_time + 1.weeks
      generate_voucher('CART', start_time, end_time, 0.9)
    end

    def generate_completion_voucher
      if C.send_new_customers_a_voucher_on_order && order&.customer && order.customer.orders.size <= 1
        start_time = Time.now + 3.weeks
        end_time = start_time + 3.months
        generate_voucher('THANKS',start_time, end_time)
      end
    end

    def generate_voucher(code_part, start_time= nil, end_time = nil, discount_multiplier = 0.85, uses = 1)
      code = "#{Base64.urlsafe_encode64(id.to_s + created_at.strftime('%d'))}#{code_part}VOUCHER".upcase.gsub('=', '')
      voucher = C::Product::Voucher.find_by(code: code)
      if !voucher = C::Product::Voucher.find_by(code: code)
        voucher = C::Product::Voucher.create!(code: code, name: code, discount_multiplier: discount_multiplier, uses: uses)
      end
      if start_time && end_time
        voucher.update(start_time: start_time, end_time: end_time)
      end
      voucher
    end
  end
end

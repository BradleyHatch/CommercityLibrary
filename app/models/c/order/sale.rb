# frozen_string_literal: true

module C
  module Order
    class Sale < ApplicationRecord
      include ChannelEnum
      include ActionView::Helpers

      scope :ordered, -> { order(id: :desc) }
      scope :carts, -> { web.awaiting_payment.or(web.pending) }

      has_many :items, foreign_key: :order_id
      has_many :products, through: :items
      has_many :notes, foreign_key: :order_id
      has_many :trackings, through: :delivery

      has_one :cart, foreign_key: :order_id, dependent: :destroy
      has_one :amazon_order, foreign_key: :order_id, autosave: true,
                             dependent: :destroy
      has_one :ebay_order, foreign_key: :order_id, autosave: true,
                           dependent: :destroy

      belongs_to :customer, optional: true
      belongs_to :shipping_address, optional: true, class_name: 'Address'
      belongs_to :billing_address, optional: true, class_name: 'Address'
      belongs_to :delivery, optional: true, dependent: :destroy
      belongs_to :payment, optional: true, dependent: :destroy
      belongs_to :product_voucher, optional: true, class_name: 'C::Product::Voucher', foreign_key: 'voucher_id'

      accepts_nested_attributes_for :notes,
                                    allow_destroy: true,
                                    reject_if: ->(note) { note[:note].blank? }
      accepts_nested_attributes_for :shipping_address
      accepts_nested_attributes_for :billing_address
      accepts_nested_attributes_for :customer, reject_if: :all_blank
      accepts_nested_attributes_for :delivery
      accepts_nested_attributes_for :trackings, allow_destroy: true, reject_if: ->(tracking) { tracking[:number].blank? && tracking[:provider].blank? }
      accepts_nested_attributes_for :payment,
                                    reject_if: lambda { |p|
                                      p[:amount_paid].blank? ||
                                        p[:amount_paid] == '0.00'
                                    }

      delegate :tracking_code, to: :delivery, allow_nil: true

      scope :exportable, -> { where(status: %i[awaiting_dispatch]) }

      # different order states
      enum status: %i[awaiting_payment
                      awaiting_dispatch
                      dispatched
                      cancelled
                      archived
                      pending]

      enum flag: %i[no_flag flagged resolved]

      enum export_status: %i[failed succeeded]

      # ensure every product has a status and info hash
      validates :status, presence: true
      validates :info, exclusion: [nil]

      # Be more discerning when going to awaiting dispatch
      with_options if: :awaiting_dispatch? do
        validates :shipping_address, presence: true
        validates :billing_address, presence: true
        validates :delivery, presence: true
        validates :payment, presence: true
      end

      with_options if: :awaiting_dispatch_and_not_manual? do
        validates :customer, presence: true
      end

      before_validation do
        awaiting_payment! unless status
        self.recieved_at ||= Time.zone.now if manual? && awaiting_dispatch?
        self.dispatched_at ||= Time.zone.now if dispatched_at.blank? && dispatched?
      end

      before_validation :set_access_token
      after_validation :store_hash

      has_paper_trail if: (proc do |order|
        order.manual? && PaperTrail.whodunnit.present?
      end)

      def archived!
        cart.destroy! if cart
        super
      end

      def toggle_flag(flag_command)
        return unless %w[no_flag! flagged! resolved!].include?(flag_command)
        send(flag_command)
      end

      def testing_completeness?
        @testing_completeness
      end

      def complete_and_valid?
        @testing_completeness = true
        valid?
      end

      def self.complete_and_valid?(&block)
        with_options if: :testing_completeness?, &block
      end

      complete_and_valid? do
        validates :customer, presence: true
        validates :shipping_address, presence: true
        validates :billing_address, presence: true
        validates :delivery, presence: true
        validates :payment, presence: true
      end

      before_destroy do
        unless in_checkout?
          shipping_address&.destroy
          billing_address&.destroy
        end
      end

      def voucher
        items.where.not(voucher_id: nil).first
      end

      def has_voucher?
        items.where.not(voucher_id: nil).any?
      end

      def in_checkout?
        cart.present?
      end

      # Tax should always default to true for orders just starting the
      # checkout. If there is no country given yet, also assume true.
      def tax_liable?
        return true if billing_address_with_fallback.blank?
        billing_address_with_fallback.country.eu?
      end

      def billing_address_with_fallback
        billing_address_without_fallback || shipping_address
      end
      
      # Allow easy falling-back of billing address
      alias_method_chain :billing_address, :fallback

      def total_price_without_tax
        Money.new(items.to_a.map { |x| x.total_price_without_tax.round(2) }.sum,
                  items&.first&.price_currency)
      end

      def total_price
        Money.new(items.to_a.map { |x| x.total_price.round(2) }.sum,
                  items.first.price_currency)
      rescue
        0
      end

      def total_tax
        result = Money.new(items.to_a.map { |x| x.total_tax.round(2) }.sum,
                  items.first.price_currency)
        return result if result.zero? || !has_voucher?
        result + (voucher.price - voucher.price/1.2)
      rescue
        0
      end

      def total_price_with_tax
        total_price
      end

      def total_delivery_pennies
        currency = items.first&.price_currency
        if currency.present? && currency != :GBP
          (delivery&.price || Money.new(0)).exchange_to(currency)
        else
          delivery&.price || Money.new(0)
        end
      end

      def total_price_with_tax_and_delivery_pennies
        currency = items.first&.price_currency
        if currency.present? && currency != :GBP
          (total_delivery_pennies + total_price_with_tax).exchange_to(currency)
        else
          total_delivery_pennies + total_price_with_tax
        end
      end

      def order_number
        id
      end

      ransacker :id do
        Arel.sql("to_char(\"#{table_name}\".\"id\", '99999')")
      end

      def has_shipping_address?
        shipping_address&.valid?
      end

      def has_delivery?
        delivery&.valid?
      end

      def payment?
        payment&.valid?
      end

      def click_and_collect?
        has_delivery? && delivery.click_and_collect?
      end

      def decrement_items(ids=nil)
        items.each do |item|
          next if item.product_id.blank? || (ids && ids.include?(item.product_id))

          new_stock = item.product.current_stock - item.quantity
          item.product.update(current_stock: new_stock)

          next unless C.keep_ebay_stock_in_sync && item.product.item_id.present?

          begin
            C::EbayJob.perform_now('update_ebay_inventories', item.product)
          rescue => e
            logger.error e.to_s
            ActionMailer::Base.mail(
              from: C.errors_email,
              to: C.errors_email,
              subject: "#{C.store_name} error pushing stock on web order finalize",
              body: "Made on order:\n\n#{self.id}" + e.to_s + "\n\n" + e.backtrace.join("\n\n")
            ).deliver
          end
        end
      end

      def send_order_notifications
        C::OrderMailer.notify_store(self).deliver_now
        C::OrderMailer.notify_customer(self).deliver_now
        C::OrderMailer.notify_voucher_used_email(self).deliver_now
        
        voucher = cart&.generate_completion_voucher
        
        if voucher
          self.update(voucher_id: voucher.id)
        end
      end

      def send_extra_order_notifications
        # i am empty so you can override me
      end

      def send_dispatch_notification
        C::OrderMailer.dispatch_nofitication(self).deliver_now
      end

      def send_tracking_emails
        if self.tracking_email_sent
          return
        end

        C::OrderMailer.tracking_email(self).deliver_now
        
        self.update(tracking_email_sent: true)
      end

      def dispatch!
        update(status: :dispatched)
        delivery.update(shipped_at: Time.zone.now)
        if amazon?
          C::AmazonOrderJob.perform_now(:fulfill_orders, [self])
        elsif ebay?
          # this code marks as dispatched on ebay
          C::EbayJob.perform_now('update_ebay_order',
                                 order: self,
                                 shipped: true)
        else
          payment.fulfil
        end
      end

      def printed!
        self.printed = true
        save!
      end

      def set_access_token
        return access_token if access_token.present?
        loop do
          self.access_token = SecureRandom.uuid
          unless C::Order::Sale.where(access_token: access_token).exists?
            return access_token
          end
        end
      end

      def store_hash
        self.body = as_json(include: :items, except: :body)
      end

      def import_details_from_customer(customer = nil)
        customer ||= self.customer
        return if customer.blank?
        self.name = customer.name
        self.email = customer.email
      end

      def build_manual_payment
        build_payment(payable: C::PaymentMethod::Manual.new)
      end

      def process
        return if processed || !awaiting_dispatch?
        items.find_each(&:process)
        update(processed: true)
      end

      # CHANNEL SPECIFIC THING RETURNER METHODS

      def channel_order_id
        case channel
        when 'amazon'
          amazon_order.amazon_id
        when 'ebay'
          ebay_order.ebay_order_id
        else
          id
        end
      end

      def user_id
        case channel
        when 'amazon'
          amazon_order.buyer_name
        when 'ebay'
          ebay_order.buyer_username
        else
          customer&.name || ''
        end
      end

      def transaction_id
        case channel
        when 'amazon'
          amazon_order.amazon_id
        when 'ebay'
          ebay_order.transaction_id
        else
          begin
            payment.payable.transaction_id
          rescue NoMethodError
            ''
          end
        end
      end

      def gateway_transaction_id
        case channel
        when 'ebay'
          ebay_order.gateway_transaction_id
        else
          # Off the top of my head, Amazon doesn't really have anything
          # similar, so I wouldn't return anything.
          ''
        end
      end

      # This is displaying the products in the orders table
      # Placed here to make the index table slightly less of a chore
      def table_product_name
        "<b>#{items.collect(&:sku).join(', ')}</b>
         <br>#{items.collect(&:name).join(', ')}"
      end

      def table_date
        recieved_at.to_s.blank? ? created_at.to_s : recieved_at.to_s
      end

      def thumbnail
        if items.any? && (product = items.first.product)
          product.master.display_thumbnail
        else
          'placeholder.png'
        end
      end

      def channel_icon
        ''
      end

      def address_name
        shipping_address&.name
      end

      def customer_display_name
        if shipping_address.present?
          customer_name = shipping_address.name || name.presence
          "#{customer_name}, #{shipping_address.address_one}"
        else
          customer&.name.presence || name
        end
      end

      def awaiting_dispatch_and_not_manual?
        awaiting_dispatch? && !manual?
      end

      def self.from_order_number(number)
        find(number)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def self.order_months
        dates = select(:id, :created_at).group_by { |m| m.created_at.beginning_of_month }.keys
        return_this = []
        dates.each { |date| return_this << [date.strftime("%B %Y"), date] }
        return_this
      end

      def self.orders_from_month(month)
        month = month.to_date
        orders = where('extract(year from created_at) = ?', month.year).where('extract(month from created_at) = ?', month.month)
        where(id: orders)
      end

      def index_table_row_class
        klass = ''
    
        if has_an_in_person_delivery_service
          klass += ' index__highlight-row'
        end
    
        if has_an_ebay_checkout_message || has_a_website_checkout_message
          klass += ' index__highlight-row--green'
        end
    
        if has_a_voucher
          klass += ' index__highlight-row--blue'
        end
    
        if pending_pro_forma?
          klass += ' index__highlight-row--yellow'
        end
    
        klass
      end

      def has_an_in_person_delivery_service
        delivery && 
        delivery.delivery_service &&
        (
          delivery.click_and_collect? ||
          [' In Store', 'NotSelected', 'In Store', 'Not Selected', 'In Person International', 'In Person', ' In Person'].include?(delivery.delivery_service.name)
        )
      end

      def has_an_ebay_checkout_message
        ebay_order && ebay_order.checkout_message.present?
      end

      def has_a_website_checkout_message
        checkout_notes.present? || (info.present? && info["checkout_notes"].present?)
      end

      def has_a_voucher
        items.pluck(:voucher_id).compact.any?
      end

      def flags
        base_flag_style = "height: 10px; width: 10px; opacity: 0.66; border-radius: 2px;"
        flags = []

        if has_an_in_person_delivery_service
          flags << content_tag(:div,"",  style: "#{base_flag_style}background-color: red" )
        end

        if has_an_ebay_checkout_message || has_a_website_checkout_message
          flags << content_tag(:div, "", style: "#{base_flag_style}background-color: green; #{flags.any? ? "margin-top: 4px;" : ""}" )
        end

        if has_a_voucher
          flags << content_tag(:div, "", style: "#{base_flag_style}background-color: blue; #{flags.any? ? "margin-top: 4px;" : ""}" )
        end

        if is_pro_forma?
          flags << content_tag(:div, "", style: "#{base_flag_style}background-color: #bba145; #{flags.any? ? "margin-top: 4px;" : ""}" )
        end

        if is_gift_wrapping?
          flags << content_tag(:div, "", style: "#{base_flag_style}background-color: #fb00ff; #{flags.any? ? "margin-top: 4px;" : ""}" )
        end
    

        flags.join.html_safe
      end

      def is_gift_wrapping?
        items.find { |item| item.gift_wrapping? }.present?
      end

      def is_pro_forma?
        payment.present? && payment.payable.present? && payment.payable.is_a?(C::PaymentMethod::ProForma)
      end

      def pending_pro_forma?
        is_pro_forma? && payment.payable.paid_at.blank?
      end

      def paid_pro_forma?
        is_pro_forma? && payment.payable.paid_at.present?
      end

      def ready_for_dispatch?
        is_pro_forma? ? paid_pro_forma? && awaiting_dispatch? : awaiting_dispatch?
      end

      INDEX_TABLE = {
        'ROW_CLASS': { toggle: { condition: 'object.export_status == \'failed\'', true: 'sage_error', false: '', nil: '' } },
        '': { image: 'thumbnail' },
        'Order': { link: { name: { call: 'order_number' },
                           options: '[object]' }, sort: 'order_number' },
        'Products': { call: 'table_product_name' },
        'Received At': {
            call: 'table_date', sort: 'created_at',
            class: { toggle: { condition: 'object.recieved_at.blank?', true: 'nil_data', false: '', nil: '' } },
        },
        'Dispatched At': {
            call: 'dispatched_at', sort: 'dispatched_at',
            class: { toggle: { condition: 'object.dispatched_at.blank?', true: 'nil_data', false: '', nil: '' } },
        },
        'Recipient': { call: 'customer_display_name', sort: 'customer_name' },
        'Channel': { call: 'channel' },
        'Status': { call: 'status.titleize' },
        '_Pro Forma': {
          toggle: { condition: 'pending_pro_forma?',
                    false: '',
                    true: {
                      link: { name: { text: 'Mark as paid' },
                              options: '[:new_pro_forma_paid_order, object]',
                              remote: true }
                    } }
        },
        'Tracking No.': {
          toggle: { condition: 'ready_for_dispatch?',
                    false: { call: 'tracking_code' },
                    true: {
                      link: { name: { text: 'Dispatch' },
                              options: '[:new_dispatch_order, object]',
                              remote: true }
                    } }
        },
        'Total': { price: {
          call: 'total_price_with_tax_and_delivery_pennies'
        } },
        '_Flags': {
          call: 'flags'
        },
        '_Print': { icon: 'print', condition: '!printed?' },
        '_Flag': { icon: 'flag', condition: '!flagged?' },
        '_Notes': { icon: 'sticky-note', condition: '!notes.any?' },

      }.freeze

      SLIM_INDEX_TABLE = INDEX_TABLE.except(:'Channel', :'Tracking No.')

      BULK_ACTIONS = [
        ['Print', :print],
        ['Export to Xero', :xero],
        ['Export to Item List Spreadsheet', :spreadsheet_item_list],
        ['Download as CSV', :download_as_csv],
        C.google_review_link&.present? ? ['Send Google Review Prompt', :send_google_review_prompt] : nil
      ].compact.freeze

      ARCHIVE_BULK_ACTIONS = (BULK_ACTIONS + [['Delete', :archive_all]]).freeze

      ransack_alias :orders_search, :shipping_address_name
    end
  end
end

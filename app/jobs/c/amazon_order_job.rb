# frozen_string_literal: true

require 'amazon/item'
require 'amazon/order'

module C
  class AmazonOrderJob < ApplicationJob
    queue_as :default

    XSD_PATH = File.join(C::Engine.root, 'app', 'assets', 'xsds')
    SHIPPING_STATUS = {
      'Shipped' => :dispatched,
      'Unshipped' => :awaiting_dispatch,
      'Canceled' => :cancelled
    }.tap { |h| h.default = :awaiting_dispatch }

    def retrieve_order_list(date_after = nil, _options = {})
      response = orders_client.list_orders(
        last_updated_after: date_after || 1.day.ago
      )
      
      return [] if response.parse['Orders'].nil?

      ensure_array(response.parse['Orders']['Order']).map do |order|
        next unless order['OrderTotal']
        next if order['OrderStatus'] == 'Pending'
        Amazon::Order.new(order)
      end
    end

    def process_new_order(order_info, options = {})
      return if order_info.cancelled?

      order = C::Order::Sale.new(
        recieved_at: order_info.purchase_date,
        channel: :amazon,
        status: order_info.status
      )

      # Set customer and addresses
      find_or_create_customer(order, order_info, options)

      if order_info.source_hash['ShippingAddress']
        order.shipping_address = parse_address(
          order_info.source_hash['ShippingAddress']
        )
        order.shipping_address.customer_id = order.customer.id
        order.shipping_address.save
      end

      taxable = is_taxable(order, order_info)

      # Items
      items = process_order_items(order, order_info, options)

      order.create_payment(amount_paid: order_info.total)

      # Set amazon off-site orderable
      order.build_amazon_order(
        amazon_id: order_info.id,
        buyer_name: order_info.buyer_name,
        buyer_email: order_info.buyer_email,
        selected_shipping: order_info.source_hash['ShipServiceLevel'],
        earliest_delivery_date: order_info.earliest_delivery_date,
        latest_delivery_date: order_info.latest_delivery_date
      )

      store_order_response(order, order_info, items)

      # Set delivery
      shipping_price = items.map do |item|
        item.shipping * item.quantity
      end.sum

      order.build_delivery(
        taxable ? { price: shipping_price } : { price: shipping_price, tax_rate: 0 } 
      )

      order.decrement_items
      order
    end

    def is_taxable(order, order_info)
      !order_info.vat_registered? && order.tax_liable?
    end

    def update_existing_order(amazon_order, order_info, _options = {})
      amazon_order.order.update(
        status: order_info.status
      )
      amazon_order.order
    end

    def process_order_items(order, order_info, _options = {})
      response = orders_client.list_order_items(order_info.id)

      taxable = is_taxable(order, order_info)
      
      items = ensure_array(response.parse['OrderItems']['OrderItem']).map do |i|
        Amazon::Item.new(i)
      end

      # New items need to be created before being added to the order.
      # Consider removing this once functionality can be assured
      items.select { |i| i.product.nil? }.each do |item|
        item.product = create_new_product(item)
      end

      # Iterate over all items and add them to the order.
      items.each do |item|
        order.items.build(
          product_id: item.product&.id,
          sku: item.sku,
          name: item.name,
          tax_rate: taxable ? item.tax_rate : 0,
          quantity: item.quantity,
          price: item.price
        )
      end

      items
    end

    def create_new_product(item)
      master = C::Product::Master.new
      master.build_main_variant(
        sku: item.sku,
        name: item.name,
        published_amazon: false,
        published_ebay: false, published_web: false,
        status: :inactive
      )
      master.save!
      master.main_variant
    end

    def acknowledge_orders(orders, _options = {})
      envelope = Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope(
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd'
        ) do
          xml.Header do
            xml.DocumentVersion '1.01'
            xml.MerchantIdentifier orders_client.merchant_id
          end
          xml.MessageType 'OrderAcknowledgement'

          orders.map.with_index(1) do |order, index|
            xml.Message do
              xml.MessageID index.to_s
              xml.OrderAcknowledgement do
                xml.AmazonOrderID order.amazon_order.amazon_id
                xml.MerchantOrderID order.order_number
                xml.StatusCode 'Success'
              end
            end
          end
        end
      end

      errors = validate_envelope(envelope)
      if errors.empty?
        # Comment out to disable Order acknowledgement

        feed_id = feeds_client.submit_feed(envelope.to_xml,
                                           '_POST_ORDER_ACKNOWLEDGEMENT_DATA_')
                              .parse['FeedSubmissionInfo']['FeedSubmissionId']

        C::AmazonProcessingQueue.push(
          [], feed_id, :acknowledgement, envelope.to_xml
        )
        envelope
      else
        errors
      end
    end

    def fulfill_orders(orders, _options = {})
      envelope = Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope(
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd'
        ) do
          xml.Header do
            xml.DocumentVersion '1.01'
            xml.MerchantIdentifier orders_client.merchant_id
          end
          xml.MessageType 'OrderFulfillment'

          orders.map.with_index(1) do |order, index|
            xml.Message do
              xml.MessageID index.to_s
              xml.OrderFulfillment do
                xml.AmazonOrderID order.amazon_order.amazon_id
                xml.FulfillmentDate order.delivery&.shipped_at&.iso8601
                if order.delivery.tracking_code.present?
                  xml.FulfillmentData do
                    xml.CarrierName order.delivery&.delivery_provider
                    xml.ShipperTrackingNumber order.delivery&.tracking_code
                  end
                end
              end
            end
          end
        end
      end

      errors = validate_envelope(envelope)
      if errors.empty?
        # Comment out to disable Order fulfillment
        feed_id = feeds_client.submit_feed(envelope.to_xml,
                                           '_POST_ORDER_FULFILLMENT_DATA_')
                              .parse['FeedSubmissionInfo']['FeedSubmissionId']

        C::AmazonProcessingQueue.push(
          [], feed_id, :fulfillment, envelope.to_xml
        )
        nil
      else
        errors
      end
    end

    def find_or_create_customer(order, order_info, _options = {})
      amazon_email = order_info.buyer_email
      customer = C::Customer.find_by(amazon_email: amazon_email)

      if customer.nil?
        customer = C::Customer.create(
          email: amazon_email,
          amazon_email: amazon_email,
          name: order_info.buyer_name.present? ? order_info.buyer_name : "N/A",
          phone: order_info.buyer_phone,
          channel: :amazon
        )
      end

      order.customer = customer
      order.import_details_from_customer
    end

    def store_order_response(order, order_info, items)
      response = ["### Order #{order_info.id}\n\n#{order_info.source_hash}"]

      items.each_with_index do |item, index|
        response << "### Item #{index + 1}/#{items.length}\n\n#{item.source_hash}"
      end

      order.amazon_order.body = response.join("\n\n")
    end

    def client_params(options = {})
      {
        merchant_id:             ENV['MWS_MERCHANT_ID'],
        aws_access_key_id:       ENV['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key:   ENV['AWS_SECRET_ACCESS_KEY'],
        primary_marketplace_id:  options.fetch(:marketplace_id,
                                               ENV['MWS_MARKETPLACE_ID']),
        auth_token:              ENV['MWS_CLIENT_TOKEN']
      }
    end

    def feeds_client(options = {})
      @feeds_client ||= MWS.feeds(client_params(options))
    end

    def orders_client(options = {})
      @orders_client ||= MWS.orders(client_params(options))
    end

    def perform(*args)
      request, data, options = args
      options ||= {}

      # Initialise the clients, to ensure the options are set
      feeds_client(options)
      orders_client(options)

      send(request, data, options)
    end

    def pull_and_process_orders(date_after = nil, options = {})
      C::BackgroundJob.process('Amazon: Order Sync') do
        group = C::SettingGroup.find_or_create_by!(name: "Amazon orders", body: 'Tracking Amazon marketplace order last ran times')

        setting_key = options.fetch(:marketplace_id, ENV['MWS_MARKETPLACE_ID'])

        unless C::Setting.get(setting_key)
          record = C::Setting.new_setting(setting_key, '2000-01-01', type: :string)
          record.update(group: group)
        end

        last_ran = C::Setting.get(setting_key).to_datetime

        should_run = (Time.current - 30.minutes) > last_ran

        if !should_run
          return []
        end

        orders = retrieve_order_list(date_after)

        orders = orders.map do |order|
          next unless order
          if (amazon_o = C::Order::AmazonOrder.find_by(amazon_id: order.id))
            update_existing_order(amazon_o, order, options)
            nil
          else
            process_new_order(order, options)
          end
        end

        orders.compact!

        good_orders = []

        orders.each do |order|
          begin
            order.save!
            good_orders.push(order)
          rescue => e
            logger.error(e.message)
            ActionMailer::Base.mail(
              from: C.errors_email,
              to: C.errors_email,
              subject: "#{C.store_name} Amazon import failure",
              body: e.to_s + "\n\n" + e.backtrace.join("\n\n")
            ).deliver
          end
        end

        acknowledge_orders(good_orders)

        C::Setting.set(setting_key, Time.current)
        
        orders
      end
    end

    def validate_envelope(envelope)
      schema = Nokogiri::XML::Schema(
        File.open(File.join(XSD_PATH, 'amzn-envelope.xsd'))
      )
      schema.validate(Nokogiri::XML(envelope.to_xml))
    end

    private

    def ensure_array(orders)
      orders.is_a?(Array) ? orders : [orders]
    end

    def parse_money(element)
      Money.new(element['Amount'].to_f * 100,
                element['CurrencyCode'])
    end

    def parse_address(element)
      return unless element
      address_one = element['AddressLine1'].presence || element['AddressLine2']
      address_two = element['AddressLine1'].present? ? element['AddressLine2'] : nil

      C::Address.find_or_initialize_by(
        name: element['Name'].present? ? element['Name'] : "N/A",
        address_one: address_one.present? ? address_one : "N/A",
        address_two: address_two,
        address_three: element['AddressLine3'],
        city: element['City'],
        region: element['StateOrRegion'],
        postcode: element['PostalCode'],
        country_id: C::Country.find_by(iso2: element['CountryCode']).id,
        phone: element['Phone']
      )
    end

    def find_item(item_info)
      C::Product::Variant.find_by(sku: item_info['SellerSKU'])
    end
  end
end

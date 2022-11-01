# frozen_string_literal: true

# All of the order related calls to eBay
# import orders grabs the list of recent orders from ebays and then loops through
# them all to process them. You can see processing flow in import_ebay_orders
# A create/update will be called in each case of processing (..or should be eek)

# all order items are destroyed and then recreated if a previously synced order
# has different items

module EbayOrders
  extend ActiveSupport::Concern

  def request_get_orders(page_number=1)
    EbayTrader::Request.new('GetOrders') do
      OrderRole 'Seller'
      NumberOfDays 3
      DetailLevel 'ReturnAll'
      Pagination do
        EntriesPerPage 100
        PageNumber page_number
      end
    end.response_hash
  end

  def request_specific_orders(ids, page_number=1)
    EbayTrader::Request.new('GetOrders') do
      OrderRole 'Seller'
      NumberOfDays 30
      DetailLevel 'ReturnAll'
      OrderIDArray do
        ids.each do |id|
          OrderID id
        end
      end
      Pagination do
        EntriesPerPage 100
        PageNumber page_number
      end
    end.response_hash
  end

  def import_ebay_orders(page_number=1)
    C::BackgroundJob.process('Ebay: Retrieve Orders') do
      ebay_orders = request_get_orders(page_number)

      next if ebay_orders[:pagination_result][:total_number_of_pages].zero? || ebay_orders[:pagination_result].blank?

      if ebay_orders[:pagination_result] && ebay_orders[:pagination_result][:total_number_of_entries].positive?
        orders = to_array(ebay_orders[:order_array][:order])
        orders.each do |order_hash|
          begin
            order_obj = Ebay::Order.new(order_hash)
            next unless (local_order = create_order(order_obj))
            process_address(local_order, order_obj)
            process_order_items(local_order, order_obj)
            process_customer(local_order, order_obj)
            process_payment(local_order, order_obj)
            process_delivery(local_order, order_obj)
            process_shipping_details(local_order, order_obj)
            process_gateway_transaction(local_order, order_obj)
            process_sales_record_number(local_order, order_obj)
            process_seller_protection(local_order)
            process_checkout_message(local_order, order_obj)
            process_status(local_order, order_obj)
            process_misc(local_order, order_obj)
          rescue => e
            logger.error(e.message)
            ActionMailer::Base.mail(
              from: C.errors_email,
              to: C.errors_email,
              subject: "#{C.store_name} eBay Order Pull Failure - Record Num: #{order_hash[:shipping_details][:selling_manager_sales_record_number]}",
              body: e.to_s + "\n\n" + e.backtrace.join("\n\n")
            ).deliver
          end
        end
      end
      # requesting another page of orders if there is another page
      import_ebay_orders(page_number + 1) unless page_number == ebay_orders[:pagination_result][:total_number_of_pages]

      # setting all orders that are awaitingpayment/pending that haven't been updated in 3 days to archived
      archive_old_awaiting_payment_orders
    end
  end

  def create_order(order_obj)
    if (order = C::Order::EbayOrder.find_by(ebay_order_id: order_obj.order_id))
      order.order
    else
      order = C::Order::Sale.create!(
        status: 0,
        flag: 0,
        channel: :ebay,
        recieved_at: order_obj.created, channel_hash: order_obj.hash
      )

      order.build_ebay_order(
        ebay_order_id: order_obj.order_id,
        buyer_email: order_obj.first_item_buyer[:email],
        body: order,
        buyer_username: order_obj.buyer_id
      )
      order
    end
  end

  def process_order_items(order, order_obj)
    if order_items_different?(order, to_array(order_obj.order_items))
      create_order_items(order, to_array(order_obj.order_items), order_obj)
    end
  end

  # diff the order items by title, sku, price an quantity
  # if any items don't match return true which cause them to get recreated
  def order_items_different?(order, order_items)
    different = false

    order_items.each do |order_item|
      sku = sku_for_order_item(order_item)

      next if order.items.find_by(
        name: order_item[:item][:title],
        ebay_sku: sku,
        price_pennies: order_item[:transaction_price].fractional,
        price_currency: order_item[:transaction_price].currency.iso_code,
        quantity: order_item[:quantity_purchased]
      )

      different = true
      break
    end

    different
  end

  def sku_for_order_item(order_item)
    sku = order_item[:item][:sku]

    # if the sku is blank check if it has variant info
    # if it does, use its sku or use the title as unique as it will be product name + joined properites
    # else it's same to use the shared item_ID
    if sku.blank?
      if order_item[:variation].present?
        sku = order_item[:variation][:sku]

        if sku.blank?
          sku = order_item[:variation][:title]
        end
        if sku.blank?
          sku = order_item[:item][:item_id]
        end
      else
        sku = order_item[:item][:item_id]
      end
    end 

    sku
  end

  def create_order_items(order, order_items, order_obj)
    product_ids = order.items.pluck(:product_id)
    order.items.destroy_all

    transaction_ids = ''

    order_items.each do |order_item|
      sku = sku_for_order_item(order_item)

      payload = {
        name: order_item[:item][:title],
        sku: sku,
        ebay_sku: sku,
        tax_rate: order.tax_liable? ? 20 : 0,
        price: order_item[:transaction_price],
        quantity: order_item[:quantity_purchased],
        ebay_order_line_item_id: order_item[:order_line_item_id]
      }

      new_item = order.items.create!(payload)

      # assigning product id to the order if the product exists
      begin
        matching_variant = C::Product::Variant.find_by(item_id: order_item[:item][:item_id])

        new_order_item = nil

        # if the order item has a variation then look up variants by sku
        # else default to the standard item_id look up
        if order_item[:variation].present?
          if order_item[:variation][:sku].present?
            new_order_item = matching_variant.master.variants.find_by_sku(order_item[:variation][:sku])
          end
        else
          new_order_item = matching_variant
        end

        if new_order_item
          new_item.update(sku: new_order_item.sku, product_id: new_order_item.id) 

          if C.keep_ebay_stock_in_sync
            new_order_item.update(current_stock: new_order_item.current_stock - order_item[:quantity_purchased])
          end
        end
      rescue
        logger.info 'Rescue when hash missing stuff in odd circumstance'
      end

      # pushing all of the transaction_ids into one string
      transaction_ids += if transaction_ids == ''
                           order_item[:transaction_id].to_s
                         else
                           ", #{order_item[:transaction_id]}"
                         end
    end

    order.ebay_order.update(transaction_id: transaction_ids)

    product_ids = product_ids - order.items.pluck(:product_id)

    order.decrement_items(product_ids)
  end

  def process_customer(order, order_obj)
    return if order_obj.first_item_buyer_email.blank?
    return if order_obj.first_item_buyer_email == 'Invalid Request'
    customer = if order.customer
                 order.customer
               else
                 C::Customer.find_or_create_by(email: order_obj.first_item_buyer_email) do |new_customer|
                   new_customer.name = order_obj.first_item_buyer_name
                   new_customer.channel = :ebay
                 end
               end
    customer.update(phone: order_obj.phone)
    order.update(customer: customer, name: customer.name, email: customer.email)
  end

  def process_payment(order, order_obj)
    if (payment = order.payment).nil?
      payment = C::Order::Payment.create!(amount_paid: order_obj.amount_paid)
      order.update(payment: payment)
    end
    if payment.amount_paid != order_obj.amount_paid
      payment.update(amount_paid: order_obj.amount_paid)
    end
  end

  def process_address(order, order_obj)
    order_obj.address[:postal_code].blank? ? postcode = 'Not given' : postcode = order_obj.address[:postal_code]

    if order_obj.valid_address?
      order_phone = order_obj.address[:phone].blank? ? "N/A" : order_obj.address[:phone]

      address = C::Address.find_or_create_by!(
        name: order_obj.address[:name],
        address_one: order_obj.address[:street1],
        address_two: order_obj.address[:street2],
        city: order_obj.address[:city_name],
        region: order_obj.address[:state_or_province],
        postcode: postcode,
        country_id: C::Country.find_by(iso2: order_obj.address[:country]).id,
        phone: order_phone
      )
      order.update(shipping_address: address, billing_address: address)
      order.shipping_address.update(customer: order.customer)
      order.billing_address.update(customer: order.customer)
    end

    order.update(phone: order_obj.address[:phone]) unless order_obj.address[:phone].blank?
  end

  def process_delivery(order, order_obj)
    service = delivery_service_create({ebay_alias: order_obj.shipping_service}, order_obj.shipping_cost)
    order.ebay_order.update(ebay_delivery_service: service.ebay_alias)

    order.create_delivery! if order.delivery.blank?

    if order_obj.shipping && order_obj.shipping_service != 'NotSelected'
      order.delivery.update(
        price_pennies: order_obj.shipping_cost.fractional,
        price_currency: order_obj.shipping_cost.currency.iso_code,
        delivery_service: service
      )
    end

    if !order.tax_liable?
      order.delivery.update(tax_rate: 0)
    end
  end

  def process_shipping_details(order, order_obj)
    if order_obj.tracking_details_present?
      to_array(order_obj.first_item_tracking).each do |tracking_detail|
        order.delivery.trackings.find_or_create_by!(number: tracking_detail[:shipment_tracking_number],
                                                    provider: tracking_detail[:shipping_carrier_used])
      end
    end
  end

  def process_gateway_transaction(order, order_obj)
    if order_obj.monetary_details && order_obj.payments_for_store
      to_array(order_obj.payments_for_store).each do |payment|
        next if payment[:reference_id].blank?
        order.ebay_order.update(gateway_transaction_id: payment[:reference_id])
      end
    end
  end

  def process_sales_record_number(order, order_obj)
    if order_obj.shipping_details
      order.ebay_order.update(sales_record_id: order_obj.sales_record_number)
    end
  end

  def process_seller_protection(order)
    return if ENV['PAYPAL_ENVIRONMENT'] != 'live' || ENV['PAYPAL_USERNAME'].blank? || ENV['PAYPAL_PASSWORD'].blank? || ENV['PAYPAL_SIGNATURE'].blank?
    return if order.ebay_order.gateway_transaction_id.blank? || order.ebay_order.seller_protection
    response = request_paypal_transaction(order)
    parse_paypal_transaction_request(order, response)
  end

  def request_paypal_transaction(order)
    uri = URI.parse('https://api-3t.paypal.com/nvp')
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      'VERSION': '204',
      'USER': ENV['PAYPAL_USERNAME'],
      'PWD': ENV['PAYPAL_PASSWORD'],
      'SIGNATURE': ENV['PAYPAL_SIGNATURE'],
      'METHOD': 'GetTransactionDetails',
      'TRANSACTIONID': order.ebay_order.gateway_transaction_id
    )
    req_options = {
      use_ssl: uri.scheme == 'https'
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response.body
  end

  def parse_paypal_transaction_request(order, response)
    if (protection = /PROTECTIONELIGIBILITY=[^&$"]+/.match(response))
      protection = protection[0].gsub('PROTECTIONELIGIBILITY=', '')
      order.ebay_order.update(seller_protection: protection == 'Eligible')
    end
  end

  def process_checkout_message(order, order_obj)
    order.ebay_order.update(checkout_message: order_obj.checkout_message) unless order_obj.checkout_message.blank?
  end

  def process_status(order, order_obj)
    if order_obj.status == 'Cancelled' || order_obj.cancelled?
      order.cancelled!
      return
    end

    if order_obj.cancel_pending?
      order.pending!
      return
    end

    if order_obj.paid_time
      order_obj.shipped_time ? order.dispatched! : order.awaiting_dispatch!
    else
      order.awaiting_payment!
    end
  end

  # blank method used for very specific ebay things that will get overriden in main application
  def process_misc(_order, _order_obj)
  end

  def update_ebay_order(opts={})
    order = opts[:order]
    request = EbayTrader::Request.new('CompleteSale') do
      OrderID order.ebay_order.ebay_order_id
      Paid true if opts[:paid]
      if opts[:shipped]
        Shipped true
        Shipment do
          order.delivery.trackings.each do |tracking|
            ShipmentTrackingDetails do
              ShipmentTrackingNumber tracking.number
              ShippingCarrierUsed tracking.provider
            end
          end
        end
      end
    end
    request.response_hash
  end

  def archive_old_awaiting_payment_orders
    C::Order::Sale.where(status: [:awaiting_payment, :pending]).where('updated_at < ?', (Time.now - 3.days)).update_all(status: :archived)
  end

end

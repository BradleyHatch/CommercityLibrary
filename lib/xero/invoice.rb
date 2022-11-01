# frozen_string_literal: true

require 'xero/item'

module C
  module Xero
    class InvoiceNotSavedError < StandardError; end

    class Invoice
      def self.sync(client, order, invoice = nil, products_synced = false)
        invoice ||= find_or_initialize(client, order)
        invoice.date ||= order.recieved_at || Time.zone.today
        invoice.due_date ||= order.recieved_at || Time.zone.today
        contact = invoice.build_contact(name: order.customer&.name || order.name)
        contact.add_address(address_params(order.billing_address))

        C::Xero::Item.sync_products(client, order.items) unless products_synced
        order.items.each do |item|
          existing_line_item = invoice.line_items.detect do |i|
            i.item_code == item.sku[0...30]
          end
          if existing_line_item
            line_item_params(item).each do |key, value|
              existing_line_item.send("#{key}=", value)
            end
          else
            invoice.add_line_item(line_item_params(item))
          end
        end

        # This is a mess, but so is trying to update the delivery price!
        delivery_line =
          invoice.line_items.detect { |i| i.description == 'Delivery' } ||
          invoice.add_line_item(description: 'Delivery')
        delivery_line.unit_amount = delivery_params(order.delivery)[:unit_amount]

        invoice.line_items.each do |item|
          item.unit_amount = item.unit_amount.to_f
        end

        invoice
      end

      def self.export!(client, order)
        invoice = sync(client, order)
        if invoice.save
          order.update(export_status: :succeeded)
        else
          order.update(export_status: :failed)
          raise InvoiceNotSavedError
        end
        invoice
      end

      def self.invoice_number(order)
        order.order_number.to_s
      end

      def self.build(client, order)
        client.Invoice.build(
          type: 'ACCREC',
          invoice_number: invoice_number(order)
        )
      end

      def self.find_or_initialize(client, order)
        client.Invoice.find(invoice_number(order))
      rescue Xeroizer::InvoiceNotFoundError
        build(client, order)
      end

      def self.map_invoices(client, orders)
        mapping = {}
        inv_number = invoice_number(order)
        orders.each { |order| mapping[inv_number] = { order: order } }
        invoices = client.Invoice.all(
          where: mapping.map do |order_number, _value|
            "InvoiceNumber==\"#{order_number}\""
          end.join(' OR ')
        )
        invoices.each do |invoice|
          mapping[invoice.invoice_number][:invoice] = invoice
        end
        mapping
      end

      def self.sync_invoices(client, orders)
        C::Xero::Item.sync_from_orders(client, orders)
        invoice_mapping = map_invoices(client, orders)
        invoices = invoice_mapping.map do |_invoice_code, pair|
          pair[:invoice] ||= build(client, pair[:order])
          sync(client, pair[:order], pair[:invoice], true)
        end
        result = client.Invoice.save_records(invoices)

        orders.update_all(export_status: result ? :succeeded : :failed)
        result
      end

      def self.delivery_params(delivery)
        # delivery_name = delivery.name
        {
          # description: delivery_name.blank? ? 'Delivery' : delivery_name,
          description: 'Delivery',
          unit_amount: delivery.price.to_s
        }
      end

      def self.line_item_params(item)
        {
          description: item.name,
          item_code: item.sku[0...30],
          quantity: item.quantity,
          unit_amount: item.price.to_s
        }
      end

      def self.address_params(address)
        {
          address_type: 'STREET',
          attention_to: address.name,
          address_line1: address.address_one,
          address_line2: address.address_two,
          address_line3: address.address_three,
          city: address.city,
          region: address.region,
          postal_code: address.postcode,
          country: address.country&.name || ''
        }
      end
    end
  end
end

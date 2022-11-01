# frozen_string_literal: true

require_relative 'exporter'

module C
  module SpreadsheetExport
    class Orders
      # Example field config:
      # FIELD_CONFIG = {
      #   ## For invoice
      #   summary_fields: %w[total_price],
      #
      #   ## For both
      #   # (Invoices note: put summarised fields at the end in order as above)
      #   item_fields: %w[name created_by quantity price],
      #
      #   ## For item stats
      #   # Defines the field by which to group the items
      #   group_field: :product_id,
      #
      #   # Each field listed won't be summed. Only the value of the first item
      #   # will be used.
      #   static_fields: %w[name created_at]
      # }.freeze

      DEFAULT_ITEM_CONFIG = {
        item_fields: %w[name created_at quantity total_price ebay_sku],
        group_field: :product_id,
        static_fields: %w[name created_at ebay_sku]
      }.freeze

      def self.find_fields(obj, field_list)
        field_list.map do |field_name|
          obj.send(field_name)
        end
      end

      def self.header_rows(field_list)
        field_list.map(&:titleize)
      end

      def self.summary_row(obj, summary_field_list, item_field_count)
        fields = find_fields(obj, summary_field_list)
        [0, (item_field_count - summary_field_list.length)].max.times do
          fields.prepend(' ')
        end
        fields
      end

      def self.group_by(items, group_field)
        grouped_items = {}
        items.each do |item|
          grouped_items[item.send(group_field)] ||= []
          grouped_items[item.send(group_field)].append(item)
        end
        grouped_items
      end

      def self.grouped_item_fields(items, item_field_list, group_field, static_fields)
        grouped_items = group_by(items, group_field)
        grouped_items.map do |_group_field, items|
          find_grouped_fields(items, item_field_list, static_fields)
        end
      end

      def self.find_grouped_fields(items, field_list, static_fields)
        field_list.map do |field|
          if static_fields.include?(field)
            items.first.send(field)
          else # Sum it
            sum_field(items, field)
          end
        end
      end

      def self.sum_field(items, field)
        items.map { |item| item.send(field) }.sum
      end

      def self.item_fields(items, item_field_list)
        items.map do |item|
          find_fields(item, item_field_list)
        end
      end

      def self.normalize_rows(rows, target_count)
        (0...(target_count - rows.length)).each { rows.append([]) }
      end

      def self.apply_padding(rows, padding)
        padding.times do
          rows.prepend([])
          rows.append([])
        end
      end

      def self.to_item_list(orders, fields, filename)
        items = C::Order::Item.where(order_id: orders.pluck(:id))
        items = items.where.not('sku = ebay_sku').order(ebay_sku: :asc) if C.order_export_ebay_sku_asc
        item_fields = fields[:item_fields]
        rows = grouped_item_fields(items, item_fields, fields[:group_field],
                                   fields[:static_fields])
        rows.prepend(header_rows(item_fields))
        apply_padding(rows, 2)
        create_spreadsheet(rows, filename)
      end

      def self.invoice(order, item_fields, summary_fields)
        item_fields(order.items, item_fields).tap do |rows|
          normalize_rows(rows, 10)
          rows.append(summary_row(order, summary_fields, item_fields.length))
          rows.prepend(header_rows(item_fields))
          apply_padding(rows, 2)
        end
      end

      def self.to_invoices(orders, fields, filename)
        invoices = orders.map do |order|
          invoice(order, fields[:item_fields], fields[:summary_fields])
        end
        create_spreadsheet(invoices.flatten(1), filename)
      end

      def self.create_spreadsheet(rows, filename)
        Exporter.new(filename, rows).export
      end
    end
  end
end

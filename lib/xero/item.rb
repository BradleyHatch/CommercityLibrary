# frozen_string_literal: true

module C
  module Xero
    class Item
      def self.map_products(client, products)
        skus = products.map(&:sku)
        items = client.Item.all(
          where: skus.map do |sku|
            "Code==\"#{sku[0...30]}\""
          end.join(' OR ')
        )
        mapping = {}
        products.each do |product|
          item = items.detect { |i| i.code == product.sku[0...30] }
          next unless item
          mapping[product.sku] = {
            item: item,
            product: product
          }
        end
        mapping
      end

      def self.sync_products(client, products)
        mapping = map_products(client, products)
        client.Item.batch_save do
          products.each do |product|
            next unless mapping[product.sku]
            mapping[product.sku] = {
              item: client.Item.build(item_params(product)),
              product: product
            }
          end
        end
        mapping
      end

      def self.sync_from_orders(client, orders)
        products = orders.map(&:items).flatten
        C::Xero::Item.sync_products(client, products)
      end

      def self.item_params(product)
        {
          name: product.name,
          code: product.sku[0...30]
        }
      end
    end
  end
end

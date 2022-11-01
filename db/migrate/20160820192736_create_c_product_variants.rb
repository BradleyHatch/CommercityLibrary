# frozen_string_literal: true
class CreateCProductVariants < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_variants do |t|
      t.references :master, index: true
      t.references :country_of_manufacture, index: true

      t.string :name
      t.text :description

      t.string :sku, unique: true

      # barcodes
      # gtin, ean, upc, isbn
      t.integer :barcode_type
      t.string :barcode_value

      t.string :asin, unique: true
      t.string :mpn, unique: true

      # product prices
      t.monetize :cost_price
      t.monetize :retail_price
      t.monetize :rrp

      # channel prices
      t.monetize :shop_price
      t.monetize :ebay_price
      t.monetize :amazon_price

      # physical values
      t.decimal :weight, default: 0.0
      t.string  :weight_unit, default: 'KG'
      t.decimal :x_dimension, default: 0.0
      t.decimal :y_dimension, default: 0.0
      t.decimal :z_dimension, default: 0.0
      t.string  :dimension_unit, default: 'M'

      t.integer :current_stock, default: 0
      t.integer :package_quantity, default: 1

      t.boolean :discontinued, default: false
      t.boolean :published, default: true

      t.boolean :published_web, default: true
      t.boolean :published_ebay, default: true
      t.boolean :published_amazon, default: true

      t.boolean :active, default: true

      t.timestamps
    end

    add_foreign_key :c_product_variants, :c_product_masters, column: :master_id, on_delete: :cascade
  end
end

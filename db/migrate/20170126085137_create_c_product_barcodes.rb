# frozen_string_literal: true
class CreateCProductBarcodes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_barcodes do |t|
      t.string :value, null: false
      t.integer :symbology, null: false
      t.integer :position

      t.belongs_to :variant, index: true

      t.timestamps
    end
  end
end

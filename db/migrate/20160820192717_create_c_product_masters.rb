# frozen_string_literal: true
class CreateCProductMasters < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_masters do |t|
      t.references :main_variant
      t.references :brand
      t.integer :manufacturer_id
      t.integer :condition

      t.timestamps
    end
  end
end

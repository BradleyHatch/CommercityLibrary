# frozen_string_literal: true
class CreateCProductImages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_images do |t|
      t.references :master
      t.references :variant

      t.string :image

      t.timestamps
    end
    add_foreign_key :c_product_images, :c_product_masters, column: :master_id, on_delete: :cascade
    add_foreign_key :c_product_images, :c_product_variants, column: :variant_id, on_delete: :nullify
  end
end

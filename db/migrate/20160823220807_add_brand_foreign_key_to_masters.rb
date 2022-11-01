# frozen_string_literal: true
class AddBrandForeignKeyToMasters < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :c_product_masters, :c_brands, column: :brand_id, on_delete: :nullify
  end
end

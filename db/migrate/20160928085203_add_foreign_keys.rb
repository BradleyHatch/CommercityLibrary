# frozen_string_literal: true
class AddForeignKeys < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :c_product_variants, :c_countries, column: :country_of_manufacture_id, on_delete: :restrict
  end
end

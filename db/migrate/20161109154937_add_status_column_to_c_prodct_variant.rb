# frozen_string_literal: true
class AddStatusColumnToCProdctVariant < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :status, :integer, default: 0
    remove_column :c_product_variants, :active
  end
end

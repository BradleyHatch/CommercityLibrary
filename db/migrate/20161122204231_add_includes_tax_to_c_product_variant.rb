# frozen_string_literal: true
class AddIncludesTaxToCProductVariant < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :includes_tax, :boolean, default: false
    add_column :c_product_variants, :delivery_override_pennies, :integer, default: 0, null: false
    add_column :c_product_variants, :delivery_override_currency, :string, default: 'GBP', null: false
  end
end

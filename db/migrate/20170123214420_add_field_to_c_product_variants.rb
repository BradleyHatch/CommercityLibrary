# frozen_string_literal: true
class AddFieldToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :manufacturer_product_url, :string
  end
end

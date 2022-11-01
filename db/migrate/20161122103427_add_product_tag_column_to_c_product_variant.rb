# frozen_string_literal: true
class AddProductTagColumnToCProductVariant < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :product_tag, :integer, default: 1
  end
end

# frozen_string_literal: true
class AddStickyColumnToCProductVariant < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :sticky, :boolean, default: false
  end
end

class AddColumnToVariant < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :order, :integer, default: 0
  end
end

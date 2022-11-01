class AddOeNumberColumnToProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :oe_number, :string
  end
end

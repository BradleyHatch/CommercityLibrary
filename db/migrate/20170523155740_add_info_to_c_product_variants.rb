class AddInfoToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :info, :jsonb, default: {}, null: false
  end
end

class AddDisplayOptionToCProductVariants < ActiveRecord::Migration[5.0]
  def change
      add_column :c_product_variants, :display_in_lists, :boolean, default: true
  end
end

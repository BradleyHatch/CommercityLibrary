class AddDisplayOnlyBoolToVariantz < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :display_only, :boolean, default: false
  end
end

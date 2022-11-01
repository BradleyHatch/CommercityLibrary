class CreateCCartItemOptionVariants < ActiveRecord::Migration[5.0]
  def change
    create_table :c_cart_item_option_variants do |t|
      t.references :price, foreign_key: { to_table: :c_prices }
      t.references :cart_item, foreign_key: { to_table: :c_cart_items }
      t.references :option_variant, foreign_key: { to_table: :c_product_option_variants }

      t.timestamps
    end
  end
end

# frozen_string_literal: true
class AddHasBeenPushedToAmazonToCProductVariants < ActiveRecord::Migration[5.0]
  def up
    add_column :c_product_variants, :has_been_pushed_to_amazon, :boolean, default: false
    C::Product::Variant.where(published_amazon: true).update_all(has_been_pushed_to_amazon: true)
  end

  def down
    remove_column :c_product_variants, :has_been_pushed_to_amazon, :boolean
  end
end

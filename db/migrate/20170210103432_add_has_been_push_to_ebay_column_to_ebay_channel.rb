# frozen_string_literal: true
class AddHasBeenPushToEbayColumnToEbayChannel < ActiveRecord::Migration[5.0]
  def up
    add_column :c_product_variants, :has_been_pushed_to_ebay, :boolean, default: false
    masters = C::Product::Channel::Ebay.where.not(item_id: nil).pluck(:master_id)
    C::Product::Variant.where(master_id: masters, main_variant: true).update_all(has_been_pushed_to_ebay: true)
  end

  def down
    remove_column :c_product_variants, :has_been_pushed_to_ebay, :boolean
  end
end

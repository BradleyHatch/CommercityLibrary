# frozen_string_literal: true
class MoveEbayItemIdToProductVariants < ActiveRecord::Migration[5.0]
  def up
    add_column :c_product_variants, :item_id, :string
    add_column :c_product_variants, :ebay_last_push_body, :json
    add_column :c_product_variants, :ebay_last_push_success, :boolean

    masters = C::Product::Channel::Ebay.where.not(item_id: nil).pluck(:master_id)

    C::Product::Variant.reset_column_information

    C::Product::Variant.where(master_id: masters, main_variant: true).each do |mv|
      mv.item_id = mv.master.ebay_channel.item_id
      mv.ebay_last_push_body = mv.master.ebay_channel.last_push_body
      mv.ebay_last_push_success = mv.master.ebay_channel.attributes['last_push_success']

      mv.save!
    end

    remove_column :c_product_channel_ebays, :item_id
    remove_column :c_product_channel_ebays, :last_push_body
    remove_column :c_product_channel_ebays, :last_push_success
  end

  def down
    add_column :c_product_channel_ebays, :item_id, :string
    add_column :c_product_channel_ebays, :last_push_body, :json
    add_column :c_product_channel_ebays, :last_push_success, :boolean

    C::Product::Channel::Ebay.reset_column_information

    main_variants = C::Product::Variant.where(main_variant: true)
    main_variants = main_variants.where.not(item_id: nil)

    main_variants.each do |mv|
      mv.master.ebay_channel.update!(item_id: mv.item_id,
                                     last_push_body: mv.ebay_last_push_body,
                                     last_push_success: mv.ebay_last_push_success)
    end

    remove_column :c_product_variants, :item_id
    remove_column :c_product_variants, :ebay_last_push_body
    remove_column :c_product_variants, :ebay_last_push_success
  end
end

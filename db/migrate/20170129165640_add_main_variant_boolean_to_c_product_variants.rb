# frozen_string_literal: true
class AddMainVariantBooleanToCProductVariants < ActiveRecord::Migration[5.0]
  def up
    add_column :c_product_variants, :main_variant, :boolean

    C::Product::Master.all.each do |master|
      variant = C::Product::Variant.find(master.main_variant_id)
      variant.update!(
        main_variant: true,
        master_id: master.id
      )
    end
    remove_column :c_product_masters, :main_variant_id, :integer
  end

  def down
    add_column :c_product_masters, :main_variant_id, :integer

    C::Product::Variant.where(main_variant: true).each do |variant|
      variant.master.update!(main_variant_id: variant.id)
    end

    remove_column :c_product_variants, :main_variant, :boolean
  end
end

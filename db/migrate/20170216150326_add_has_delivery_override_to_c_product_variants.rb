# frozen_string_literal: true
class AddHasDeliveryOverrideToCProductVariants < ActiveRecord::Migration[5.0]
  def up
    add_column :c_product_variants, :has_delivery_override, :boolean, default: false

    C::Product::Variant.reset_column_information

    C::Product::Variant.where.not(delivery_override_pennies: 0).update_all(
      has_delivery_override: true
    )
  end

  def down
    remove_column :c_product_variants, :has_delivery_override, :boolean
  end
end

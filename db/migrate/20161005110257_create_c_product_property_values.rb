# frozen_string_literal: true
class CreateCProductPropertyValues < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_property_values do |t|
      t.string :value

      t.belongs_to :property_key
      t.belongs_to :variant

      t.timestamps
    end

    add_index :c_product_property_values, [:property_key_id, :value, :variant_id], unique: true, name: 'property_value_validation_index'
  end
end

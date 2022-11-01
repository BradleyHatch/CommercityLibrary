# frozen_string_literal: true
class CreateCProductPropertyKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_property_keys do |t|
      t.string :key

      t.belongs_to :master

      t.timestamps
    end

    add_index :c_product_property_keys, [:master_id, :key], unique: true
  end
end

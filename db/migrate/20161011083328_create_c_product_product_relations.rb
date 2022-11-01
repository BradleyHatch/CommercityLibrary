# frozen_string_literal: true
class CreateCProductProductRelations < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_product_relations do |t|
      t.belongs_to :product, index: true
      t.belongs_to :related, index: true

      t.timestamps
    end

    add_index :c_product_product_relations, [:product_id, :related_id], unique: true
  end
end

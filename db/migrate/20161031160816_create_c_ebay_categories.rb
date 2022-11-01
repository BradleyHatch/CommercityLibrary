# frozen_string_literal: true
class CreateCEbayCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :c_ebay_categories do |t|
      t.boolean :best_offer_enabled
      t.boolean :auto_pay_enabled
      t.integer :category_id
      t.integer :category_level
      t.string :category_name
      t.integer :category_parent_id

      t.integer :parent_id

      t.timestamps
    end
  end
end

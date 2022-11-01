# frozen_string_literal: true
class CreateCAmazonProductTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_amazon_product_types do |t|
      t.string :name

      t.timestamps
    end
  end
end

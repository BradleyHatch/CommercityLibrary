# frozen_string_literal: true
class CreateCAmazonProductAttributes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_amazon_product_attributes do |t|
      t.belongs_to :product_type, class_name: 'C::AmazonProductType'
      t.string :name

      t.timestamps
    end
  end
end

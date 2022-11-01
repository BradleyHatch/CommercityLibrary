# frozen_string_literal: true
class CreateCProductCategorizations < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_categorizations do |t|
      t.references :product
      t.references :category

      t.timestamps
    end
  end
end

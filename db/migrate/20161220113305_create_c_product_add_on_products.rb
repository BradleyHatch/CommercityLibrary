# frozen_string_literal: true
class CreateCProductAddOnProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_add_on_products do |t|
      t.belongs_to :main, index: true
      t.belongs_to :add_on, index: true

      t.timestamps
    end
  end
end

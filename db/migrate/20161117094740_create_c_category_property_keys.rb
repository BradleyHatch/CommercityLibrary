# frozen_string_literal: true
class CreateCCategoryPropertyKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :c_category_property_keys do |t|
      t.belongs_to :category
      t.belongs_to :property_key

      t.timestamps
    end
  end
end

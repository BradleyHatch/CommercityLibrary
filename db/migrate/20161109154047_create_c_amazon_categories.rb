# frozen_string_literal: true
class CreateCAmazonCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :c_amazon_categories do |t|
      t.string :name

      t.timestamps
    end
  end
end

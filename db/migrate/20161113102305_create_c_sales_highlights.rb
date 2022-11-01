# frozen_string_literal: true
class CreateCSalesHighlights < ActiveRecord::Migration[5.0]
  def change
    create_table :c_sales_highlights do |t|
      t.string :image
      t.string :url

      t.timestamps
    end
  end
end

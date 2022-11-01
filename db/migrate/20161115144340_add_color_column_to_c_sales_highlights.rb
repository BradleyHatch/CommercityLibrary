# frozen_string_literal: true
class AddColorColumnToCSalesHighlights < ActiveRecord::Migration[5.0]
  def change
    add_column :c_sales_highlights, :color, :string
  end
end

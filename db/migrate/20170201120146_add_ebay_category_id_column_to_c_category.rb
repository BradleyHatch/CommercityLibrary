# frozen_string_literal: true
class AddEbayCategoryIdColumnToCCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :c_categories, :ebay_category_id, :integer
  end
end

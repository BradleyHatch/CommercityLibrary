# frozen_string_literal: true
class AddColumnsToPages < ActiveRecord::Migration[5.0]
  def up
    add_column :c_pages, :parent_id, :integer unless column_exists?(:c_pages, :parent_id)
    add_column :c_pages, :weight, :integer
  end

  def down
    add_column :c_pages, :parent_id, :integer
    add_column :c_pages, :weight, :integer
  end
end

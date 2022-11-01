# frozen_string_literal: true
class AddTargetToCMenuItems < ActiveRecord::Migration[5.0]
  def change
    add_column :c_menu_items, :target, :string
  end
end

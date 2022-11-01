class AddDescriptionToCOrderItem < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_items, :description, :text
  end
end

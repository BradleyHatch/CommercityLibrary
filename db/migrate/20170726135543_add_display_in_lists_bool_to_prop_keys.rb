class AddDisplayInListsBoolToPropKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_property_keys, :display, :boolean, default: true
  end
end

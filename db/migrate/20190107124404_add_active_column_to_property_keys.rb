class AddActiveColumnToPropertyKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_property_values, :active, :boolean, default: true
  end
end

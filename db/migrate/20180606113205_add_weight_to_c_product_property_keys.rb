class AddWeightToCProductPropertyKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_property_keys, :weight, :integer, default: 0
  end
end

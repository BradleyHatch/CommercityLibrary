class AddQuantityToBundleItems < ActiveRecord::Migration[5.0]
  def change
    add_column :c_bundle_items, :quantity, :int
  end
end

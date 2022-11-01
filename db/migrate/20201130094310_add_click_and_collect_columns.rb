class AddClickAndCollectColumns < ActiveRecord::Migration[5.0]
  def change
    add_column :c_delivery_services, :click_and_collect, :boolean, default: false
    add_column :c_product_variants, :click_and_collect, :boolean, default: false
  end
end

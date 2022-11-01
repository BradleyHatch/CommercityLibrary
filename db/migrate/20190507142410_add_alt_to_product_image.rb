class AddAltToProductImage < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_images, :alt, :string, default: ""
  end
end

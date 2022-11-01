class AddSubTitleToCProductsWebChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_webs, :sub_title, :string
  end
end

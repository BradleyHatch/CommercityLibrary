class AddEbcFieldsToCProductChannelAmazons < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_amazons, :ebc_logo, :string
    add_column :c_product_channel_amazons, :ebc_description, :string
    add_column :c_product_channel_amazons, :ebc_module1_heading, :string
    add_column :c_product_channel_amazons, :ebc_module1_body, :string
    add_column :c_product_channel_amazons, :ebc_module2_heading, :string
    add_column :c_product_channel_amazons, :ebc_module2_sub_heading, :string
    add_column :c_product_channel_amazons, :ebc_module2_body, :string
    add_column :c_product_channel_amazons, :ebc_module2_image, :string
  end
end

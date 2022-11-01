class AddGlobalShippingColumnToEbayShipping < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_channel_ebays, :global_shipping, :boolean, default: false

  end
end

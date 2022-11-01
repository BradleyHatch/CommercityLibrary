class AddTrackingLinkToDeliveryProviders < ActiveRecord::Migration[5.0]
  def change
    add_column :c_delivery_providers, :tracking_link, :string, default: ""
  end
end

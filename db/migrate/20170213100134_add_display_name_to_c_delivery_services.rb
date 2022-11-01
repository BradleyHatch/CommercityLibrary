# frozen_string_literal: true
class AddDisplayNameToCDeliveryServices < ActiveRecord::Migration[5.0]
  def change
    add_column :c_delivery_services, :display_name, :string
  end
end

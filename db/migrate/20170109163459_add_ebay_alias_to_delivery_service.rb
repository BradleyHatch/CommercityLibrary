# frozen_string_literal: true
class AddEbayAliasToDeliveryService < ActiveRecord::Migration[5.0]
  def change
    add_column :c_delivery_services, :ebay_alias, :string
  end
end

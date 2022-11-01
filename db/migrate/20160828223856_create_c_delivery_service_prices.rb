# frozen_string_literal: true
class CreateCDeliveryServicePrices < ActiveRecord::Migration[5.0]
  def change
    create_table :c_delivery_service_prices do |t|
      t.decimal :min_weight
      t.decimal :max_weight
      t.text :country_ids
      t.monetize :price

      t.belongs_to :delivery_service, index: true

      t.timestamps
    end
  end
end

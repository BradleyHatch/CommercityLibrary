# frozen_string_literal: true
class CreateCDeliveryServices < ActiveRecord::Migration[5.0]
  def change
    rename_table :c_delivery_services, :c_delivery_services_old
    create_table :c_delivery_services do |t|
      t.string :name
      t.references :provider
      t.integer :channel

      t.timestamps
    end
  end
end

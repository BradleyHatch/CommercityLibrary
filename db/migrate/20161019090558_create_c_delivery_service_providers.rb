# frozen_string_literal: true
class CreateCDeliveryServiceProviders < ActiveRecord::Migration[5.0]
  def change
    create_table :c_delivery_service_providers do |t|
      t.string :name

      t.timestamps
    end
  end
end

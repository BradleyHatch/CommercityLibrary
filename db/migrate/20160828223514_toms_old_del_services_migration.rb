# frozen_string_literal: true
class TomsOldDelServicesMigration < ActiveRecord::Migration[5.0]
  def change
    create_table :c_delivery_services do |t|
      t.string :name
      t.string :code
      t.boolean :active
      t.boolean :default

      t.belongs_to :delivery_service_provider, dependent: :destroy

      t.timestamps
    end
  end
end

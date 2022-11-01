class CreateCDeliveryServiceVariants < ActiveRecord::Migration[5.0]
  def change
    create_table :c_delivery_service_variants do |t|
      t.belongs_to :variant
      t.belongs_to :service

      t.timestamps
    end
  end
end

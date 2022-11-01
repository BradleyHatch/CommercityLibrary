# frozen_string_literal: true
class CreateCProductReservations < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_reservations do |t|
      t.string :name
      t.string :email
      t.string :phone

      t.integer :product_variant_id

      t.timestamps
    end
  end
end

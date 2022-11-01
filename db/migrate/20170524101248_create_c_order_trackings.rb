class CreateCOrderTrackings < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_trackings do |t|

      t.string :provider
      t.string :number

      t.integer :delivery_id

      t.timestamps
    end
  end
end

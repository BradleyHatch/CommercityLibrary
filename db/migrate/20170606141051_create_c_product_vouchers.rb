class CreateCProductVouchers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_vouchers do |t|
      t.string :name
      t.string :code, null: false
      t.boolean :restricted, default: false
      t.decimal :discount_multiplier, default: 1.0
      t.monetize :flat_discount
      t.monetize :per_item_discount
      t.monetize :minimum_cart_value
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :active, default: true

      t.timestamps
    end
    add_index(:c_product_vouchers, :code)
  end
end

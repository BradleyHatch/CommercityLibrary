# frozen_string_literal: true
class CreateCProductChannelEbays < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_ebays do |t|
      t.references :master

      t.string :name
      t.string :sub_title
      t.references :category
      t.text :body

      t.string :item_id
      t.boolean :ended, default: false

      t.integer :condition
      t.string  :condition_description
      t.string :country
      t.integer :dispatch_time
      t.string :duration

      t.monetize :start_price
      t.boolean :payment_method_paypal
      t.boolean :payment_method_postal
      t.boolean :payment_method_cheque
      t.boolean :payment_method_other
      t.boolean :payment_method_cc
      t.boolean :payment_method_escrow

      t.string :postcode, default: :NR24AQ

      t.string :domestic_shipping_service
      t.string :domestic_shipping_type
      t.monetize :domestic_shipping_service_cost
      t.monetize :domestic_shipping_service_additional_cost

      t.boolean :free_shipping
      t.boolean :pickup_in_store
      t.boolean :click_collect_collection_available

      t.integer :international_shipping_service
      t.monetize :international_shipping_service_cost
      t.monetize :international_shipping_service_additional_cost

      t.boolean :returns_accepted
      t.string :restocking_fee_value_option
      t.string :returns_description
      t.string :refund_option
      t.string :returns_within
      t.string :returns_cost_paid_by

      t.boolean :warranty_offered
      t.string :warranty_duration
      t.string :warranty_type

      t.timestamps
    end
    add_foreign_key :c_product_channel_ebays, :c_product_masters, column: :master_id, on_delete: :restrict
  end
end

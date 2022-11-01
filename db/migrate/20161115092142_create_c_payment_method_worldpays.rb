# frozen_string_literal: true
class CreateCPaymentMethodWorldpays < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_worldpays do |t|
      t.string :ip
      t.string :payment_token
      t.string :order_code

      t.timestamps
    end
  end
end

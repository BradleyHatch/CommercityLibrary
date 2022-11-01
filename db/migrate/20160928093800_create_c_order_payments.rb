# frozen_string_literal: true
class CreateCOrderPayments < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_payments do |t|
      t.monetize :amount_paid

      t.timestamps
    end
  end
end

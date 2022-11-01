# frozen_string_literal: true
class AddPaymentTokenToPayment < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_payments, :payment_token, :string
    add_column :c_order_payments, :payer_id, :string
    add_column :c_order_payments, :ip_address, :string
  end
end

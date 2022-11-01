# frozen_string_literal: true
class RemovePaymentTokenFromPayments < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_order_payments, :payment_token
    remove_column :c_order_payments, :payer_id
    remove_column :c_order_payments, :ip_address
  end
end

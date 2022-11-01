# frozen_string_literal: true
class AddPayableToPayments < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_order_payments, :payable, polymorphic: true, index: true
  end
end

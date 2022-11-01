# frozen_string_literal: true
class AddCustomerAccountToCCustomer < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_customers, :customer_account, index: true
  end
end

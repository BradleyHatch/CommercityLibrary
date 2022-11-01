class AddPaymentTypeToCCustomerAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :c_customer_accounts, :payment_type, :integer, default: 0, null: false
  end
end

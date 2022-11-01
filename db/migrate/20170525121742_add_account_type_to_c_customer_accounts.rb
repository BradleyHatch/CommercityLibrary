class AddAccountTypeToCCustomerAccounts < ActiveRecord::Migration[5.0]
  def up
    return if column_exists?(:c_customer_accounts, :account_type)
    add_column :c_customer_accounts, :account_type, :integer, default: 0, null: false
  end

  def down
    remove_column :c_customer_accounts, :account_type
  end
end

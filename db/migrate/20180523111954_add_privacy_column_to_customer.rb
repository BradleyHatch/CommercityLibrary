class AddPrivacyColumnToCustomer < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :accepted_privacy_policy, :boolean
    add_column :c_customer_accounts, :accepted_privacy_policy, :boolean
  end
end

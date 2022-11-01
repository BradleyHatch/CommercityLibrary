# frozen_string_literal: true
class RemoveDeviseFromCCustomer < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_customers, :encrypted_password, :string, null: false, default: ''

    remove_column :c_customers, :reset_password_token, :string
    remove_column :c_customers, :reset_password_sent_at, :datetime

    remove_column :c_customers, :sign_in_count, :integer, default: 0, null: false
    remove_column :c_customers, :current_sign_in_at, :datetime
    remove_column :c_customers, :last_sign_in_at, :datetime
    remove_column :c_customers, :current_sign_in_ip, :string
    remove_column :c_customers, :last_sign_in_ip, :string
  end
end

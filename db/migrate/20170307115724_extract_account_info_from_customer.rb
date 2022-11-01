# frozen_string_literal: true
class ExtractAccountInfoFromCustomer < ActiveRecord::Migration[5.0]
  def up
    C::Customer.where.not(encrypted_password: '').each do |customer|
      ca = customer.create_account!(email: customer.email, password: '12345678901234567890'.split('').shuffle.join)

      ca.encrypted_password     = customer.encrypted_password
      ca.reset_password_token   = customer.reset_password_token
      ca.reset_password_sent_at = customer.reset_password_sent_at
      ca.remember_created_at    = customer.remember_created_at
      ca.sign_in_count          = customer.sign_in_count
      ca.current_sign_in_at     = customer.current_sign_in_at
      ca.last_sign_in_at        = customer.last_sign_in_at
      ca.current_sign_in_ip     = customer.current_sign_in_ip
      ca.last_sign_in_ip        = customer.last_sign_in_ip

      ca.save!
    end
  end

  def down
    C::CustomerAccount.all.each do |ca|
      customer = ca.customer

      customer.encrypted_password     = ca.encrypted_password
      customer.reset_password_token   = ca.reset_password_token
      customer.reset_password_sent_at = ca.reset_password_sent_at
      customer.remember_created_at    = ca.remember_created_at
      customer.sign_in_count          = ca.sign_in_count
      customer.current_sign_in_at     = ca.current_sign_in_at
      customer.last_sign_in_at        = ca.last_sign_in_at
      customer.current_sign_in_ip     = ca.current_sign_in_ip
      customer.last_sign_in_ip        = ca.last_sign_in_ip

      customer.save!
      ca.destroy!
    end
  end
end

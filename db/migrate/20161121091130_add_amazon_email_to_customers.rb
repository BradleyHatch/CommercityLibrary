# frozen_string_literal: true
class AddAmazonEmailToCustomers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_customers, :amazon_email, :string, index: true
  end
end

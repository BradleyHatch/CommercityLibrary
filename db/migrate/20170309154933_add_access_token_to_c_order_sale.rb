# frozen_string_literal: true
class AddAccessTokenToCOrderSale < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :access_token, :uuid, index: true
  end
end

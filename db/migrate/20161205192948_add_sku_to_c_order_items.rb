# frozen_string_literal: true
class AddSkuToCOrderItems < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_items, :sku, :string
  end
end

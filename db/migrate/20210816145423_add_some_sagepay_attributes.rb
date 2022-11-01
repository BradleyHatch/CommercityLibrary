class AddSomeSagepayAttributes < ActiveRecord::Migration[5.0]
  def change
    add_column :c_payment_method_sagepays, :threed_secure_status, :string
    add_column :c_order_sales, :transaction_suffix, :integer, default: 0, null: false
  end
end

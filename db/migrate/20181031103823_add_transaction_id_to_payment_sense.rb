class AddTransactionIdToPaymentSense < ActiveRecord::Migration[5.0]
  def change
    add_column :c_payment_method_payment_senses, :transaction_id, :string
  end
end

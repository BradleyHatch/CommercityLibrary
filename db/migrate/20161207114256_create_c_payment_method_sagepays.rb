# frozen_string_literal: true
class CreateCPaymentMethodSagepays < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_sagepays do |t|
      t.string :ip
      t.string :card_identifier
      t.string :merchant_session_key
      t.string :transaction_id

      t.timestamps
    end
  end
end

# frozen_string_literal: true
class CreateCPaymentMethodPaypalExpresses < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_paypal_expresses do |t|
      t.string :payer_id
      t.string :ip
      t.string :payment_token

      t.timestamps
    end
  end
end

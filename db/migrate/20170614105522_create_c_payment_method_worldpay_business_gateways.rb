class CreateCPaymentMethodWorldpayBusinessGateways < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_worldpay_business_gateways do |t|
      t.string :ip
      t.string :transaction_id
      t.json :response_body

      t.timestamps
    end
  end
end

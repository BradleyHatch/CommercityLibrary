class CreateCPaymentMethodPaymentSenses < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_payment_senses do |t|
      t.string :ip
      t.string :cross_reference
      t.string :request_string
      t.string :response_string

      t.timestamps
    end
  end
end

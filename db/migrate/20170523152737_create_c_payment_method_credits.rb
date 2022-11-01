class CreateCPaymentMethodCredits < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_credits do |t|
      t.string :ip
      t.datetime :paid_at

      t.timestamps
    end
  end
end

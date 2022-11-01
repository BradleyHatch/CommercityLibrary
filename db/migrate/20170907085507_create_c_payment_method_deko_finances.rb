class CreateCPaymentMethodDekoFinances < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_deko_finances do |t|
      t.string :ip
      t.string :deko_id
      t.string :unique_reference, null: false, index: { unique: true }
      t.integer :last_status, null: false, default: 0
      t.jsonb :csn

      t.timestamps
    end
  end
end

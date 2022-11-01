# frozen_string_literal: true
class CreateCPaymentMethodManuals < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_manuals do |t|
      t.string :body

      t.timestamps
    end
  end
end

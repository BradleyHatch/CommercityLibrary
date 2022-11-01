# frozen_string_literal: true
class CreateCPaymentMethodV12Finances < ActiveRecord::Migration[5.0]
  def change
    create_table :c_payment_method_v12_finances do |t|
      t.string :ip
      t.string :application_id
      t.string :application_guid

      t.timestamps
    end
  end
end

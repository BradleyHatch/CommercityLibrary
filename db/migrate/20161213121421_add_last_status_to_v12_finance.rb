# frozen_string_literal: true
class AddLastStatusToV12Finance < ActiveRecord::Migration[5.0]
  def change
    add_column :c_payment_method_v12_finances, :last_status, :integer, default: 0
  end
end

# frozen_string_literal: true
class AddSparseFieldToCustomer < ActiveRecord::Migration[5.0]
  def change
    add_column :c_customers, :sparse, :boolean, default: false
  end
end

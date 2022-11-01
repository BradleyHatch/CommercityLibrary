class AddSageFieldsToCCustomer < ActiveRecord::Migration[5.0]
  def change
    add_column :c_customers, :sage_ref, :string
  end
end

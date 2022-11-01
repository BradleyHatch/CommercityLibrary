class RemovesUniquenessIndexAndAddsAnotherIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :c_customers, name: "index_c_customers_on_email"
    add_index :c_customers, :email
  end
end

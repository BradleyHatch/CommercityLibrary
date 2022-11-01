class AddColumnToRes < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_reservations, :reference, :string
  end
end

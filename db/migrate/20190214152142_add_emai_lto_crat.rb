class AddEmaiLtoCrat < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :email, :string
  end
end

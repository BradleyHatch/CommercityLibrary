class AddMailerColumnsToCart < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :abandoned_mailout_three_day, :boolean, default: false
    add_column :c_carts, :abandoned_mailout_five_day, :boolean, default: false
    add_column :c_carts, :abandoned_mailout_seven_day, :boolean, default: false
  end
end

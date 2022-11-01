class AddColumnToCart < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :country_didnt_match_from_paypal, :boolean, default: false
  end
end

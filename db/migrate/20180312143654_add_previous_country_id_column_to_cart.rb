class AddPreviousCountryIdColumnToCart < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :previous_country_id, :integer
  end
end

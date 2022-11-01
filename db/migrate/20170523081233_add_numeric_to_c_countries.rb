class AddNumericToCCountries < ActiveRecord::Migration[5.0]
  def change
    add_column :c_countries, :numeric, :string, limit: 3, null: false, default: '000'
  end
end

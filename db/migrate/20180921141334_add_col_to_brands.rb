class AddColToBrands < ActiveRecord::Migration[5.0]
  def change
    add_column :c_brands, :in_menu, :boolean, default: false
  end
end

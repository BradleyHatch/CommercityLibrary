class AddImage2ToCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :c_categories, :image_alt, :string
  end
end

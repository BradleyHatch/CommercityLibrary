class AddAnohterImagetocollcetion < ActiveRecord::Migration[5.0]
  def change
    add_column :c_collections, :image_alt, :string
  end
end

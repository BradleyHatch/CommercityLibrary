class AddCollectionTypeEnumToCollections < ActiveRecord::Migration[5.0]
  def change
    add_column :c_collections, :collection_type, :integer, default: 0
  end
end

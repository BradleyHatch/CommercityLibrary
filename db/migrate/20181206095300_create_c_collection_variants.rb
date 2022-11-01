class CreateCCollectionVariants < ActiveRecord::Migration[5.0]
  def change
    create_table :c_collection_variants do |t|
      t.references :collection
      t.references :variant
      
      t.timestamps
    end
  end
end

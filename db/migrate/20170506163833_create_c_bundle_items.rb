class CreateCBundleItems < ActiveRecord::Migration[5.0]
  def change
    create_table :c_bundle_items do |t|
      t.references :bundled_variant
      t.references :variant
      t.monetize :price

      t.timestamps
    end
  end
end

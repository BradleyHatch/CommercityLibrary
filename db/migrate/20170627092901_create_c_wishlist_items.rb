class CreateCWishlistItems < ActiveRecord::Migration[5.0]
  def change
    create_table :c_wishlist_items do |t|
      t.integer :customer_id
      t.integer :variant_id

      t.timestamps
    end
  end
end

class CreateCProductOffers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_offers do |t|
      t.references :variant, foreign_key: { to_table: :c_product_variants }
      t.monetize :price
      t.integer :quantity
      t.string :sender_email
      t.integer :status
      t.integer :source
      t.string :sender_id
      t.string :offer_id

      t.timestamps
    end
  end
end

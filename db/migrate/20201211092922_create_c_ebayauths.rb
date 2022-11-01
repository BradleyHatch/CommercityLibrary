class CreateCEbayauths < ActiveRecord::Migration[5.0]
  def change
    create_table :c_ebayauths do |t|
      t.text :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end

class CreateCPriceChanges < ActiveRecord::Migration[5.0]
  def change
    create_table :c_price_changes do |t|      
      t.monetize :without_tax
      t.monetize :with_tax
      t.decimal  :tax_rate

      t.monetize :was_without_tax
      t.monetize :was_with_tax
      t.decimal  :was_tax_rate
      
      t.string :reason

      t.belongs_to :user
      t.belongs_to :price
      t.datetime :changed_at

      t.timestamps
    end
  end
end

class AddLocalEbayErrorsToMasters < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_masters, :ebay_local_errors, :jsonb, default: []
  end
end

class CreateCProductChannelEbayFeatureImages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_ebay_feature_images do |t|
      t.references :ebay
      t.references :image

      t.timestamps
    end
  end
end

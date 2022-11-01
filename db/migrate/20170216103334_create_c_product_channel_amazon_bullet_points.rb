# frozen_string_literal: true
class CreateCProductChannelAmazonBulletPoints < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_amazon_bullet_points do |t|
      t.string :value
      t.belongs_to :product_channel, index: { name: 'index_amzn_bullet_points_on_product_channel_id' }

      t.timestamps
    end
  end
end

# frozen_string_literal: true
class AddProductTypesToAmazonChannel < ActiveRecord::Migration[5.0]
  def change
    add_belongs_to :c_product_channel_amazons, :product_type
  end
end

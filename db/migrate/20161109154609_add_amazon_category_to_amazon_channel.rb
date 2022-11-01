# frozen_string_literal: true
class AddAmazonCategoryToAmazonChannel < ActiveRecord::Migration[5.0]
  def change
    add_belongs_to :c_product_channel_amazons, :amazon_category
    add_belongs_to :c_amazon_product_types, :amazon_category
  end
end

# frozen_string_literal: true
class AddAmazonProductTypeIdToCategory < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_categories, :amazon_product_type
  end
end

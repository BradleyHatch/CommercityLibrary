# frozen_string_literal: true
class DefaultToFalseForPublishedOnVariant < ActiveRecord::Migration[5.0]
  def up
    change_column_default :c_product_variants, :published_amazon, false
    change_column_default :c_product_variants, :published_ebay, false
  end

  def down
    change_column_default :c_product_variants, :published_amazon, true
    change_column_default :c_product_variants, :published_ebay, true
  end
end

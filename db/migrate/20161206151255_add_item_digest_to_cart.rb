# frozen_string_literal: true
class AddItemDigestToCart < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :item_digest, :string
  end
end

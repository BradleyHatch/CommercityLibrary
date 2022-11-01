# frozen_string_literal: true
class RemoveReferencesFromCarts < ActiveRecord::Migration[5.0]
  def change
    remove_reference :c_carts, :shipping_address
    remove_reference :c_carts, :billing_address
    remove_reference :c_carts, :delivery
    remove_reference :c_carts, :payment
  end
end

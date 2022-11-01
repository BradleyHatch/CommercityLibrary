# frozen_string_literal: true
class RemoveMasterAssociationFromPropertyKeys < ActiveRecord::Migration[5.0]
  def change
    remove_reference :c_product_property_keys, :master
  end
end

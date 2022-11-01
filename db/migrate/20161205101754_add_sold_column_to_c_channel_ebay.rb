# frozen_string_literal: true
class AddSoldColumnToCChannelEbay < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :sold, :boolean, default: false
  end
end

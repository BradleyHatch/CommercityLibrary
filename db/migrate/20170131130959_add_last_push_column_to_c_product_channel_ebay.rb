# frozen_string_literal: true
class AddLastPushColumnToCProductChannelEbay < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :last_push_body, :json
    add_column :c_product_channel_ebays, :last_push_success, :boolean
  end
end

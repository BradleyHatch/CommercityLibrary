# frozen_string_literal: true
class AddLastPushToCProductChannelAmazons < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_amazons, :last_push_success, :boolean
    add_column :c_product_channel_amazons, :last_push_body, :json
  end
end

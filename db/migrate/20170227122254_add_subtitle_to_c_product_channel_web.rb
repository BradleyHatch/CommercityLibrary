# frozen_string_literal: true
class AddSubtitleToCProductChannelWeb < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_webs, :subtitle, :string
  end
end

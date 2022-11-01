class AddLastSyncTimeColumnToEBayChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :last_sync_time, :datetime
  end
end

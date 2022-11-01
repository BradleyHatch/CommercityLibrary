class AddSalesRecordIdToebayorder < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_ebay_orders, :sales_record_id, :string
  end
end

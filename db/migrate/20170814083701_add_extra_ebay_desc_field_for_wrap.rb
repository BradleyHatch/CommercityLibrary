class AddExtraEbayDescFieldForWrap < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_channel_ebays, :wrap_text_1, :text
    add_column :c_product_channel_ebays, :wrap_text_2, :text

  end
end

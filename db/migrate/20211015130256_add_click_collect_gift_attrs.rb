class AddClickCollectGiftAttrs < ActiveRecord::Migration[5.0]
  def change
    add_column :c_carts, :prefer_click_and_collect, :boolean, default: false, null: false
  end
end

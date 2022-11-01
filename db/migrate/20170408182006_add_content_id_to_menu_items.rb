class AddContentIdToMenuItems < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_menu_items, :content, index: true
  end
end

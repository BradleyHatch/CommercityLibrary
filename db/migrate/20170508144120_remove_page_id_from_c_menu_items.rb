class RemovePageIdFromCMenuItems < ActiveRecord::Migration[5.0]
  def up
    C::MenuItem.where(content_id: nil).update_all('content_id=page_id')
    remove_reference :c_menu_items, :page
  end

  def down
    add_reference :c_menu_items, :page
    C::MenuItem.update_all('page_id=content_id')
  end
end

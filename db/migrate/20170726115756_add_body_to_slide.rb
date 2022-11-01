class AddBodyToSlide < ActiveRecord::Migration[5.0]
  def change
    add_column :c_slides, :body, :text
  end
end

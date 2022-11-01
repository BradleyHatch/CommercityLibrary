# frozen_string_literal: true
class AddPreviewImageToCImage < ActiveRecord::Migration[5.0]
  def change
    add_column :c_images, :preview_image, :boolean, default: false
  end
end

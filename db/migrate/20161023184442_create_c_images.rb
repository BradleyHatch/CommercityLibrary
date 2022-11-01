# frozen_string_literal: true
class CreateCImages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_images do |t|
      t.string   :image
      t.string   :alt
      t.string   :caption
      t.integer  :imageable_id
      t.string   :imageable_type
      t.boolean  :featured_image, default: false

      t.timestamps
    end
  end
end

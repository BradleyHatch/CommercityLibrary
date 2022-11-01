# frozen_string_literal: true
class CreateCProductChannelImages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_images do |t|
      # channel fk's
      t.references :channel, polymorphic: true

      # image fk
      t.references :image

      t.string :name
      t.integer :order

      t.timestamps
    end

    add_foreign_key :c_product_channel_images, :c_product_images, column: :image_id, on_delete: :nullify
  end
end

class CreateCTemplateBlocks < ActiveRecord::Migration[5.0]
  def change
    create_table :c_template_blocks do |t|

      t.string :name
      t.text :body
      t.string :image
      t.string :url
      t.integer :size
      t.integer :kind_of
      t.integer :region_id

      t.timestamps
    end
  end
end

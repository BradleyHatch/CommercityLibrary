class CreateCTemplateRegions < ActiveRecord::Migration[5.0]
  def change
    create_table :c_template_regions do |t|

      t.string :name
      t.integer :content_id

      t.timestamps
    end
  end
end

class CreateCContents < ActiveRecord::Migration[5.0]
  def change
    create_table :c_contents do |t|
      t.string :name
      t.text :body
      t.integer :content_type
      t.string :template
      t.text :summary
      t.references :parent
      t.integer :weight
      t.string :slug
      t.boolean :published, default: true
      t.boolean :protected, default: false
      t.boolean :featured, default: false
      t.boolean :root, default: false
      t.references :created_by
      t.references :updated_by

      t.timestamps
    end
  end
end

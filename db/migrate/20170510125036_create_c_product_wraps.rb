class CreateCProductWraps < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_wraps do |t|

      t.string :name
      t.text :wrap

      t.timestamps
    end
  end
end

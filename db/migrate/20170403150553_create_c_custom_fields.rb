class CreateCCustomFields < ActiveRecord::Migration[5.0]
  def change
    create_table :c_custom_fields do |t|

      t.string :name

      t.timestamps
    end
  end
end

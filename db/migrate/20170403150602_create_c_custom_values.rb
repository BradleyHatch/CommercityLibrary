class CreateCCustomValues < ActiveRecord::Migration[5.0]
  def change
    create_table :c_custom_values do |t|

      t.string :value

      t.integer :custom_field_id
      t.references :custom_recordable, polymorphic: true, index: {name: :custom_field_index}

      t.timestamps
    end
  end
end

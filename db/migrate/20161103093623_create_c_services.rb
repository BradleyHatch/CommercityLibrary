# frozen_string_literal: true
class CreateCServices < ActiveRecord::Migration[5.0]
  def change
    create_table :c_services do |t|
      t.string   :name
      t.text     :body
      t.integer  :parent_id
      t.integer  :weight

      t.timestamps
    end
  end
end

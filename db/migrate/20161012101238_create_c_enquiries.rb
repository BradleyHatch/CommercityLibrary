# frozen_string_literal: true
class CreateCEnquiries < ActiveRecord::Migration[5.0]
  def change
    create_table :c_enquiries do |t|
      t.string   :name
      t.string   :email
      t.text     :body

      t.timestamps
    end
  end
end

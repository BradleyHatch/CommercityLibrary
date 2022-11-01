# frozen_string_literal: true
class CreateCTestimonials < ActiveRecord::Migration[5.0]
  def change
    create_table :c_testimonials do |t|
      t.text     :quote
      t.string   :author
      t.integer  :project_id

      t.timestamps
    end
  end
end

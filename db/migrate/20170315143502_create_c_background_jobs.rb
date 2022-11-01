# frozen_string_literal: true
class CreateCBackgroundJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :c_background_jobs do |t|
      t.string :name
      t.datetime :last_ran

      t.timestamps
    end
  end
end

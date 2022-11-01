# frozen_string_literal: true
class AddFieldsToBackgroundJobs < ActiveRecord::Migration[5.0]
  def change
    add_column :c_background_jobs, :message, :string
    add_column :c_background_jobs, :job_size, :integer
    add_column :c_background_jobs, :job_processed_count, :integer
  end
end

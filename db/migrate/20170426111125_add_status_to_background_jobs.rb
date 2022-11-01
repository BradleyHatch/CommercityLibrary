class AddStatusToBackgroundJobs < ActiveRecord::Migration[5.0]
  def change
    add_column :c_background_jobs, :status, :integer, default: 0, null: false
  end
end

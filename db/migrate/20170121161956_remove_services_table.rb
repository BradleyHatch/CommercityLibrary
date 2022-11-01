# frozen_string_literal: true
class RemoveServicesTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :c_services
    drop_table :c_service_hierarchies
  end
end

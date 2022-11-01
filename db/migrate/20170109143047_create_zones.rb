# frozen_string_literal: true
class CreateZones < ActiveRecord::Migration[5.0]
  def change
    create_table :c_zones do |t|
      t.string :name
    end

    add_column :c_countries, :zone_id, :integer
  end
end

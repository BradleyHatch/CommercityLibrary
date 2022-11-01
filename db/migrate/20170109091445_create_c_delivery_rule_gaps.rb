# frozen_string_literal: true
class CreateCDeliveryRuleGaps < ActiveRecord::Migration[5.0]
  def change
    create_table :c_delivery_rule_gaps do |t|
      t.references :rule
      t.integer :lower_bound, default: 0
      t.decimal :cost

      t.timestamps
    end
  end
end

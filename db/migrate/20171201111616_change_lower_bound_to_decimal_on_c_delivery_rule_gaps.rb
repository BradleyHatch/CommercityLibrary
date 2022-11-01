class ChangeLowerBoundToDecimalOnCDeliveryRuleGaps < ActiveRecord::Migration[5.0]
  def change
    change_column :c_delivery_rule_gaps, :lower_bound, :decimal, default: 0
  end
end

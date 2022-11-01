# frozen_string_literal: true

module C
  module Delivery
    class Rule < ApplicationRecord
      has_many :gaps, class_name: 'Delivery::RuleGap', dependent: :destroy
      accepts_nested_attributes_for :gaps,
                                    allow_destroy: true,
                                    reject_if: lambda { |attributes|
                                      attributes[:lower_bound].blank? ||
                                        attributes[:cost].blank?
                                    }
      belongs_to :service, class_name: 'Delivery::Service'
      belongs_to :zone

      validates :service, :base_price, presence: true

      monetize :min_cart_price_pennies
      monetize :max_cart_price_pennies, allow_nil: true

      # enum zone: [???]

      def calculate_cost_from(weight)
        total = base_price
        remaining_weight = weight
        gaps.ordered.each do |gap|
          next unless gap.lower_bound < remaining_weight
          gap_size = remaining_weight - gap.lower_bound
          total += gap_size * gap.cost
          remaining_weight -= gap_size
        end
        total
      end
    end
  end
end

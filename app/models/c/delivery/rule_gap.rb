# frozen_string_literal: true

module C
  module Delivery
    class RuleGap < ApplicationRecord
      belongs_to :rule, class_name: 'Delivery::Rule'
      validates :rule, :cost, :lower_bound, presence: true

      scope :ordered, -> { order(lower_bound: :desc) }
    end
  end
end

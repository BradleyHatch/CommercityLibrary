# frozen_string_literal: true

module C
  module Orderable
    extend ActiveSupport::Concern

    included do
      has_one :_weight,
              dependent: :destroy,
              class_name: 'C::Weight',
              as: :orderable
      accepts_nested_attributes_for :_weight

      scope :ordered, (-> { includes(:_weight).order('c_weights.value asc') })

      before_validation :_weight

      # Sets the weight to one above the higest value in the weight table, or
      # zero if there are no weights. This is an easy way to ensure the
      # orderable goes to the bottom of the list.
      def _weight
        super || build__weight(value: (C::Weight.maximum('value') || -1) + 1)
      end

      def weight
        _weight.value
      end

      def weight=(val)
        _weight.value = val
      end

      def self.update_order(ordered_ids)
        order = ordered_ids.each_with_index.map { |_, index| { weight: index } }
        update(ordered_ids, order)
      end
    end
  end
end

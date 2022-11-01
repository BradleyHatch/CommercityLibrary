# frozen_string_literal: true

module C
  module Product
    class PropertyKey < ApplicationRecord
      has_many :property_values, dependent: :destroy
      accepts_nested_attributes_for :property_values,
                                    allow_destroy: true,
                                    reject_if: ->(val) { val[:value].blank? }
      has_many :variants, through: :property_values
      has_many :category_property_keys
      has_many :categories, through: :category_property_keys

      validates :key, presence: true, uniqueness: true

      def values
        property_values.pluck(:value).sort
      end

      def grouped_values
        values.uniq
      end

      INDEX_TABLE = {
        'Key': { primary: 'key' }
      }.freeze
    end
  end
end

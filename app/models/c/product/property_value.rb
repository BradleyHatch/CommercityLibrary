# frozen_string_literal: true

module C
  module Product
    class PropertyValue < ApplicationRecord

      belongs_to :variant, optional: false
      belongs_to :property_key, optional: false

      delegate :key, to: :property_key

      validates :property_key, presence: true
      validates :value, presence: true, uniqueness: { scope: %i[variant property_key] }
    end
  end
end

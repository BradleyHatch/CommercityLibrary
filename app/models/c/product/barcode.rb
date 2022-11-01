# frozen_string_literal: true

module C
  module Product
    class Barcode < ApplicationRecord

      scope :unassigned, -> { where(variant_id: nil).order(created_at: :asc) }

      enum symbology: %i[UPC EAN GTIN ISBN]

      belongs_to :variant, class_name: C::Product::Variant

      validates :value, presence: true, uniqueness: { scope: :symbology }

      validates :symbology,
                presence: true,
                uniqueness: { scope: :variant, unless: 'variant_id.nil?' }

      def self.symbology_array
        symbologies.keys
      end

      INDEX_TABLE = {
        # Just using value doesn't work, so call self to be sure
        'Value': { primary: 'value' },
        'Symbology': { call: 'symbology' },
        'Added': { call: 'created_at.strftime("%d/%m/%Y")' }
      }.freeze
    end
  end
end

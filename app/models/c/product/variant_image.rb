# frozen_string_literal: true

module C
  module Product
    class VariantImage < ApplicationRecord
      include Orderable

      default_scope -> { includes(:image) }
      belongs_to :variant
      belongs_to :image
    end
  end
end

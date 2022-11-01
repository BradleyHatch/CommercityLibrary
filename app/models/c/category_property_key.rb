# frozen_string_literal: true

module C
  class CategoryPropertyKey < ApplicationRecord
    belongs_to :category
    belongs_to :property_key, class_name: C::Product::PropertyKey
  end
end

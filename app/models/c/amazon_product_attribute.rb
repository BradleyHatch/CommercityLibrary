# frozen_string_literal: true

module C
  class AmazonProductAttribute < ApplicationRecord
    belongs_to :product_type, class_name: 'C::AmazonProductType'

    validates :name, presence: true
    validates :product_type, presence: true
  end
end

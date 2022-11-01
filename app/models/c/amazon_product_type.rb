# frozen_string_literal: true

module C
  class AmazonProductType < ApplicationRecord
    belongs_to :amazon_category
    has_one :category
    has_many :amazon_product_attributes,
             dependent: :destroy,
             foreign_key: :product_type_id
    accepts_nested_attributes_for :amazon_product_attributes

    validates :name, presence: true
  end
end

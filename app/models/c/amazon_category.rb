# frozen_string_literal: true

module C
  class AmazonCategory < ApplicationRecord
    has_many :amazon_product_types, dependent: :destroy
    validates :name, presence: true

    def pluck_product_types
      types = amazon_product_types.order(created_at: :asc).pluck(:name, :id)
      types.map { |name, id| [name.titlecase, id] }
    end

    def self.pluck_categories
      order(created_at: :asc).pluck(:name, :id).map do |name, id|
        [name.titlecase, id]
      end
    end
  end
end

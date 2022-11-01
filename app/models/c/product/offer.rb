# frozen_string_literal: true

module C
  class Product::Offer < ApplicationRecord
    belongs_to :variant

    validates :variant, presence: true
    validates :source, presence: true

    enum source: %i[web ebay amazon]
    enum status: %i[pending resolved]

    scope :ordered, -> { order(created_at: :desc) }

    monetize :price_pennies
  end
end

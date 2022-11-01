# frozen_string_literal: true

module C
  module Product
    class ProductRelation < ApplicationRecord
      belongs_to :product, class_name: 'C::Product::Master',
                           foreign_key: :product_id
      belongs_to :related, class_name: 'C::Product::Master',
                           foreign_key: :related_id

      validates :product_id, presence: true
      validates :related_id, uniqueness: { scope: :product_id }, presence: true
    end
  end
end

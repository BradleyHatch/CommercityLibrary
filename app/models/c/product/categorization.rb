# frozen_string_literal: true

module C
  module Product
    class Categorization < ApplicationRecord
      belongs_to :product,
                 class_name: 'C::Product::Master',
                 foreign_key: :product_id
      belongs_to :category
    end
  end
end

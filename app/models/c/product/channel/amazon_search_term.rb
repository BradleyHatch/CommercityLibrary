# frozen_string_literal: true

module C
  module Product
    module Channel
      class AmazonSearchTerm < ApplicationRecord
        belongs_to :product_channel, class_name: 'Product::Channel::Amazon'
      end
    end
  end
end

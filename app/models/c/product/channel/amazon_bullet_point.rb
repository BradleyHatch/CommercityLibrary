# frozen_string_literal: true

module C
  module Product
    module Channel
      class AmazonBulletPoint < ApplicationRecord
        default_scope { order(created_at: :asc) }
        
        belongs_to :product_channel, class_name: 'Product::Channel::Amazon'

        validates :value, presence: true
        validates :product_channel, presence: true
      end
    end
  end
end

# frozen_string_literal: true

module C
  module Product
    class Feature < ApplicationRecord
      enum feature_type: %i[image text link]

      has_many :products, through: :product_features
      has_many :product_features

      mount_uploader :image

      def get_content
        return "<img src='#{image.url}' />" if self.feature_type == 'image'
        return "<div class='product-feature-text'>#{body}</div>" if self.feature_type == 'text'
        return "<div class='product-feature-text'><a href='#{link}'>#{name}</a></div>" if self.feature_type == 'link'
        return ''
      end

    end
  end
end

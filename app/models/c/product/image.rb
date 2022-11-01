# frozen_string_literal: true

module C
  module Product
    class Image < ApplicationRecord
      belongs_to :master
      belongs_to :variant
      include Orderable

      has_many :channel_images, dependent: :destroy
      has_many :feature_images, class_name: 'C::Product::Channel::Ebay::FeatureImage', dependent: :destroy

      mount_uploader :image, C::ProductImageUploader

      validates :image, presence: true
    end
  end
end

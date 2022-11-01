# frozen_string_literal: true

module C
  class Image < ApplicationRecord
    include Orderable

    validates :image, presence: true
    belongs_to :imageable, polymorphic: true
    

    mount_uploader :image, ImageUploader
  end
end

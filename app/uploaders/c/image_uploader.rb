# encoding: utf-8
# frozen_string_literal: true

module C
  class ImageUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick unless Rails.env.test?

    def store_dir
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    version :thumbnail, if: :test_env? do
      process resize_and_pad: [150, 150]
    end

    version :preview, if: :test_env? do
      process resize_to_fit: [100, 100]
    end

    version :cropped_square, if: :test_env? do
      process resize_to_fill: [300, 300]
    end

    version :square, if: :test_env? do
      process resize_to_fit: [300, 300]
    end

    version :big_sq, if: :test_env? do
      process resize_and_pad: [600, 400]
    end

    version :large, if: :test_env? do
      process resize_to_fill: [1000, 600]
    end

    version :banner, if: :test_env? do
      process resize_to_fill: [1200, 400]
    end

    version :wide_banner, if: :test_env? do
      process resize_to_fit: [1500, 400]
    end

    version :fourthree, if: :test_env? do
      process resize_to_fit: [800, 600]
    end

    protected

    def test_env?(_)
      !Rails.env.test?
    end
  end
end

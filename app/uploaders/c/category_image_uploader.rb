# encoding: utf-8
# frozen_string_literal: true

module C
  class CategoryImageUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick unless Rails.env.test?

    def store_dir
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    version :preview, if: :test_env? do
      process resize_to_fit: [100, 100]
    end

    version :banner, if: :test_env? do
      process resize_to_fit: [1000, 250]
    end

    version :grid_square, if: :test_env? do
      process resize_and_pad: [200, 200]
    end

    def extension_white_list
      %w[jpg jpeg gif png]
    end

    protected

    def test_env?(_)
      !Rails.env.test?
    end
  end
end

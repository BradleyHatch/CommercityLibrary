# encoding: utf-8
# frozen_string_literal: true

module C
  class BrandImageUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick unless Rails.env.test?

    def store_dir
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    version :thumb, if: :test_env? do
      process resize_and_pad: [75, 75, :transparent, 'Center']
    end

    version :display, if: :test_env? do
      process resize_and_pad: [400, 250, :transparent, 'Center']
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

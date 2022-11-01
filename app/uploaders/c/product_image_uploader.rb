# encoding: utf-8
# frozen_string_literal: true

module C
  class ProductImageUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick unless Rails.env.test?

    def store_dir
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    version :thumbnail do
      process resize_and_pad: [150, 150] unless Rails.env.test?
    end

    version :grid_square, if: :test_env? do
      process resize_and_pad: [200, 200]
    end

    version :square, if: :test_env? do
      process resize_and_pad: [600, 600]
    end

    version :product_standard, if: :test_env? do
      process resize_and_pad: [800, 600]
    end

    version :product_standard_no_pad, if: :test_env? do
      process resize_to_fit: [800, 800]
    end

    version :product_large, if: :test_env? do
      process resize_and_pad: [1600, 1200]
    end

    version :ebay_image do
      unless Rails.env.test?
        process :convert_jpg
        process :ebay_watermark
        def full_filename(for_file = model.image.file)
          temp_name = for_file.split('.')
          "ebay_#{temp_name[0]}.jpg"
        end
      end
    end

    def convert_jpg
      manipulate! do |img|
        img.combine_options do |c|
          c.background '#FFFFFF'
          c.alpha 'remove'
        end
        img.format 'jpg'
        img
      end
    end

    def extension_white_list
      %w[jpg jpeg gif png]
    end

    def ebay_watermark
      logo = MiniMagick::Image.open(Rails.root.join('app', 'assets', 'images', 'watermark.png'))
      if logo
        logo.resize('150x150')
        manipulate! do |img|
          result = img.composite(logo) do |c|
            c.compose 'Over'
            c.gravity 'Southeast'
          end
          result
        end
      end
    rescue
      Rails.logger.info 'Cannot build watermark'
    end

    protected

    def test_env?(_)
      !Rails.env.test?
    end
  end
end

class ConvertBlockImageToImages < ActiveRecord::Migration[5.0]

  def up
    C::Template::Block.find_each do |block|
      next if block.image.blank?

      url = block.image.url

      if !Rails.env.development?
        block.images.create!(remote_image_url: url)
      else
        block.images.create!(image: File.open(Rails.root.to_s + '/public/' + url))
      end

    end
  end

  def down
    C::Template::Block.find_each do |block|

      if block.images.any?
        url = block.images.ordered.first.image.url
        if !Rails.env.development?
          block.update!(remote_image_url: url)
        else
          block.update!(image: File.open(Rails.root.to_s + '/public/' + url))
        end
      end

    end
  end

end

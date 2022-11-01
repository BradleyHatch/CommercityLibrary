class MoveVariantIdToCProductVariantImages < ActiveRecord::Migration[5.0]
  def up
    C::Product::Image.where.not(variant_id: nil).find_each do |img|
      C::Product::VariantImage.create!(
        variant_id: img.variant_id,
        image_id: img.id
      )
    end
  end

  def down
    C::Product::VariantImage.all.find_each do |varimg|
      img = C::Product::Image.find(varimg.image_id)
      img.update!(variant_id: varimg.variant_id) rescue puts "Error ignored on Product::Image #{img.id}"
      img.destroy!
    end
  end
end

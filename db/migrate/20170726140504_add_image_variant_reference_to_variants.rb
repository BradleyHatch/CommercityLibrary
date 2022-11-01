class AddImageVariantReferenceToVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :image_variant_id, :integer
  end
end

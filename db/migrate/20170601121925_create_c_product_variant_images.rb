class CreateCProductVariantImages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_variant_images do |t|
      t.belongs_to :variant
      t.belongs_to :image

      t.timestamps
    end
  end
end

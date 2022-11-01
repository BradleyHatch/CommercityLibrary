class AddNotesToVariantDimensions < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variant_dimensions, :notes, :text, default: ""
  end
end

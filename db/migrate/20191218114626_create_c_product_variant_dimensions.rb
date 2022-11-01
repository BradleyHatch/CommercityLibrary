class CreateCProductVariantDimensions < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_variant_dimensions do |t|
      t.decimal  "weight",                         default: "0.0"
      t.string   "weight_unit",                    default: "KG"
      t.decimal  "x_dimension",                    default: "0.0"
      t.decimal  "y_dimension",                    default: "0.0"
      t.decimal  "z_dimension",                    default: "0.0"
      t.string   "dimension_unit",                 default: "M"

      t.belongs_to :variant

      t.timestamps
    end
  end
end

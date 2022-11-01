class CreateCProductOptionVariants < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_option_variants do |t|
      t.references :option, foreign_key: { to_table: :c_product_options }
      t.references :variant, foreign_key: { to_table: :c_product_variants }

      t.timestamps
    end
  end
end

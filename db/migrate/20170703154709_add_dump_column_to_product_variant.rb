class AddDumpColumnToProductVariant < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_variants, :import_dump, :text

  end
end

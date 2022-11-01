class AddAmazonProductPipelineIdToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :amazon_product_pipeline_id, :string
    add_index :c_product_variants, :amazon_product_pipeline_id, unique: true
  end
end

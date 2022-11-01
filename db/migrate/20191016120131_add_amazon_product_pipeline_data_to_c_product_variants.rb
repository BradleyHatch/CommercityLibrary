class AddAmazonProductPipelineDataToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :amazon_product_pipeline_data, :jsonb, default: {}
  end
end

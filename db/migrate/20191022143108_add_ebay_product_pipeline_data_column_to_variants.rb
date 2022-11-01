class AddEbayProductPipelineDataColumnToVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :ebay_product_pipeline_data, :jsonb, default: {}
  end
end

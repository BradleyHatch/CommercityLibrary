class AddShouldPushToAmazonPipelineToVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :should_push_to_amazon_pipeline, :boolean, default: false
  end
end

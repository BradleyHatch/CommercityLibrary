class AddCompulsoryBoolToProductOptions < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_options, :compulsory, :boolean, default: false
  end
end

class AddMyriadUpdateToVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :myriad_updated_at, :datetime
  end
end

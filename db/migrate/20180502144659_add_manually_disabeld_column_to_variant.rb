class AddManuallyDisabeldColumnToVariant < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_variants, :manually_disabled, :boolean, default: false

  end
end

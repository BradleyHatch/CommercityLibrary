class RemovePostCodeDefault < ActiveRecord::Migration[5.0]
  def change

    change_column_default(:c_product_channel_ebays, :postcode, nil)

  end
end

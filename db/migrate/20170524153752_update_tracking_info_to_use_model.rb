class UpdateTrackingInfoToUseModel < ActiveRecord::Migration[5.0]
  def up

    C::Order::Delivery.where.not(tracking_code: ['', nil], delivery_provider: ['', nil]).map { |delivery|
      delivery.trackings.create!(number: delivery.read_attribute(:tracking_code), provider: delivery.read_attribute(:delivery_provider))
    }

    remove_column :c_order_deliveries, :tracking_code
    remove_column :c_order_deliveries, :delivery_provider

  end


  def down

    add_column :c_order_deliveries, :tracking_code, :string
    add_column :c_order_deliveries, :delivery_provider, :string

    C::Order::Sale.reset_column_information

    C::Order::Tracking.all.map { |tracking|

      tracking.delivery.update(tracking_code: tracking.number, delivery_provider: tracking.provider)

    }


  end

end

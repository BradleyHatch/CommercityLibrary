class UpdateOldEbayShipping < ActiveRecord::Migration[5.0]
  def up
    domestic_channels = C::Product::Channel::Ebay.where.not(delivery_service_id: nil)
    international_channels = C::Product::Channel::Ebay.where.not(international_shipping_service_id: nil)

    domestic_channels.map{ |channel|
      channel.shipping_services.find_or_create_by!(delivery_service_id: channel.delivery_service_id,
                                        cost_pennies: channel.domestic_shipping_service_cost_pennies,
                                        cost_currency: channel.domestic_shipping_service_cost_currency,
                                        additional_cost_pennies: channel.domestic_shipping_service_additional_cost_pennies,
                                        additional_cost_currency: channel.domestic_shipping_service_additional_cost_currency
                                      )
    }

    international_channels.map{ |channel|
      channel.shipping_services.find_or_create_by!(delivery_service_id: channel.international_shipping_service_id,
                                        cost_pennies: channel.international_shipping_service_cost_pennies,
                                        cost_currency: channel.international_shipping_service_cost_currency,
                                        additional_cost_pennies: channel.international_shipping_service_additional_cost_pennies,
                                        additional_cost_currency: channel.international_shipping_service_additional_cost_currency,
                                        international: true
                                      )
    }

    remove_column :c_product_channel_ebays, :international_shipping_service_id
    remove_monetize :c_product_channel_ebays, :international_shipping_service_cost
    remove_monetize :c_product_channel_ebays, :international_shipping_service_additional_cost

    remove_column :c_product_channel_ebays, :delivery_service_id
    remove_monetize :c_product_channel_ebays, :domestic_shipping_service_cost
    remove_monetize :c_product_channel_ebays, :domestic_shipping_service_additional_cost
  end

  def down

    add_column :c_product_channel_ebays, :international_shipping_service_id, :integer
    add_monetize :c_product_channel_ebays, :international_shipping_service_cost
    add_monetize :c_product_channel_ebays, :international_shipping_service_additional_cost

    add_column :c_product_channel_ebays, :delivery_service_id, :integer
    add_monetize :c_product_channel_ebays, :domestic_shipping_service_cost
    add_monetize :c_product_channel_ebays, :domestic_shipping_service_additional_cost

    C::Product::Channel::Ebay.reset_column_information

    services = C::Product::Channel::Ebay::ShippingService.all
    services.map { |service|
      if service.international
        service.ebay.update(international_shipping_service_id: service.delivery_service_id,
                            international_shipping_service_cost_pennies: service.cost_pennies,
                            international_shipping_service_cost_currency: service.cost_currency,
                            international_shipping_service_additional_cost_pennies: service.additional_cost_pennies,
                            international_shipping_service_additional_cost_currency: service.additional_cost_currency
                            )
      else
        service.ebay.update(delivery_service_id: service.delivery_service_id,
                            domestic_shipping_service_cost_pennies: service.cost_pennies,
                            domestic_shipping_service_cost_currency: service.cost_currency,
                            domestic_shipping_service_additional_cost_pennies: service.additional_cost_pennies,
                            domestic_shipping_service_additional_cost_currency: service.additional_cost_currency
                            )
      end
    }
  end

end

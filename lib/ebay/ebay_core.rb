# frozen_string_literal: true

# All of the essential methods that don't have a better place to go


module EbayCore
  extend ActiveSupport::Concern

  # Used to set autehnication when pushing to eBay
  def config
    EbayTrader.configure do |config|
      config.ebay_api_version = 981
      config.environment = ENV['EBAY_ENVIRONMENT'].to_sym
      config.ebay_site_id = 3
      config.ssl_verify = false

      config.auth_token = ENV['EBAY_AUTH_TOKEN']
      config.dev_id  = ENV['EBAY_DEV_ID']
      config.app_id  = ENV['EBAY_APP_ID']
      config.cert_id = ENV['EBAY_CERT_ID']
      config.ru_name = ENV['EBAY_RU_NAME']

      config.price_type = :money
    end
  end

  # This is called in sync methods and get order methods so it is here as it
  # isn't specific to either file
  def delivery_service_create(ebay_alias, _cost, _channel_id=nil)
    if (delivery_service = C::Delivery::Service.ebay.find_by(ebay_alias))
      delivery_service
    else
      delivery_provider = C::Delivery::Provider
                          .find_or_create_by(name: 'eBay Provider')
      C::Delivery::Service.create(name: ebay_alias[:ebay_alias],
                                  ebay_alias: ebay_alias[:ebay_alias],
                                  provider: delivery_provider, channel: :ebay)
    end
  end

  # Forcing hashes into array from eBay return
  # TODO replace with this by just wrapping stuff with Array() zzz
  def to_array(hash)
    if hash.class.to_s == 'ActiveSupport::HashWithIndifferentAccess' ||
       hash.class.to_s == 'String'
      [hash]
    else
      hash
    end
  end

  def get_ebay_details(detail_name=nil)
    request = EbayTrader::Request.new('GeteBayDetails') do
      DetailName detail_name if detail_name
    end
    request.response_hash
  end

  def set_unavailable_text
    response = get_ebay_details('ProductDetails')
    val = response[:product_details][:product_identifier_unavailable_text]
    C::SettingGroup.find_or_create_by!(name: 'ebay_unavailable', body: 'Text for missing eBay details')
    C::Setting.new_setting('ebay_unavailable', val, group: 'ebay_unavailable', type: :string) unless C::Setting.get('ebay_unavailable')
    C::Setting.set('ebay_unavailable', val)
  end

end

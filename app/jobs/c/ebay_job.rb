# frozen_string_literal: true

require 'ebay_trader'
require 'ebay_trader/request'
require 'net/http'
require 'uri'

# Requiring files that contain generic/specific methods in the lib/ebay dir
# If you are looking for a method and it is not where it should logically be,
# check the ebay_core file
require 'ebay/ebay_core'
require 'ebay/ebay_categories'
require 'ebay/ebay_mass'
require 'ebay/ebay_orders'
require 'ebay/ebay_product_pull'
require 'ebay/ebay_product_push'
require 'ebay/ebay_stock'

require 'ebay/ebay_offer_pull'
require 'ebay/ebay_message_pull'
require 'ebay/ebay_message_push'

require 'ebay/ebay_session'

require 'ebay/classes/listing'
require 'ebay/classes/order'

module C
  class EbayJob < ApplicationJob
    include ::EbayCore
    include ::EbayCategories
    include ::EbayMass
    include ::EbayOrders
    include ::EbayProductPull
    include ::EbayProductPush
    include ::EbayStock

    include ::EbayOfferPull
    include ::EbayMessagePull
    include ::EbayMessagePush

    include ::EbaySession

    # queue_as :default

    def perform(*args)
      request, options = args
      config
      options.present? ? send(request, options) : send(request)
    end
  end
end

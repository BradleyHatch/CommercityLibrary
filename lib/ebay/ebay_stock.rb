# frozen_string_literal: true

# Gets all of the item id's from all of the active eBay listings and finds
# variants which match an item id and have been updated since the job last ran
# and individually pushes the stock of each product to eBay
module EbayStock
  extend ActiveSupport::Concern

  def set_out_of_stock_control
    EbayTrader::Request.new('SetUserPreferences') do
      OutOfStockControlPreference true
    end
  end

  def mass_stock_update
    C::BackgroundJob.process('Ebay: Sync Stock') do |job|
      listing_ids = to_array(mass_listings).map { |listing| listing[:item_id] }
      products = C::Product::Variant.where(item_id: listing_ids)
      masters = C::Product::Master.where('updated_at > ?', job.last_ran)

      products.where(master: masters).in_groups(4).each do |four_products| 
        update_ebay_inventories(four_products)
      end
    end
  end

  def update_ebay_inventories(listings)

    listings_array = Array.wrap(listings).compact

    return if listings_array.empty?

    # Ouch, my API limits
    # set_out_of_stock_control
    request = EbayTrader::Request.new('ReviseInventoryStatus') do
      ErrorLanguage 'en_GB'
      WarningLevel 'High'
      DetailLevel 'ReturnAll'
      listings_array.each do |listing|
        InventoryStatus do
          ItemID listing.item_id
          Quantity listing.quantity_check
          StartPrice listing.price(channel: :ebay, fallback: :web).to_s
        end
      end
    end
    request.response_hash
  end

  def inactive_listing(variant)
    # Ouch, my API limits
    # set_out_of_stock_control
    request = EbayTrader::Request.new('ReviseInventoryStatus') do
      InventoryStatus do
        ItemID variant.item_id
        Quantity 0
      end
    end
    variant.update_push_body(request.response_hash)
  end

  def make_listings_inactive(val)
    master = val[:obj]
    master.variants.each { |variant| make_children_inactive(master, variant) }
  end

  private

  # make each variant listing inactive if the main variant is inactive
  def make_children_inactive(master, variant)
    if master.main_variant.inactive? ||
       !master.main_variant.published_ebay ||
       variant.inactive? ||
       !variant.published_ebay
      inactive_listing(variant)
    end
  end
end

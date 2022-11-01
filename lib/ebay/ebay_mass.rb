# frozen_string_literal: true

# This file contains a bunch of methods that do bulk requests and pushes to ebay
#
# mass_listings gets all of your active listings
# make_listings_inactive sets a master and its variants to have 0 stock on ebay
# create_from_ebay takes all of your active listings and creates local records
# for them
#
# create_from_ebay_uk does the same but only ones with GBP prices

module EbayMass
  extend ActiveSupport::Concern

  # MASS PRODUCT JOBS
  def mass_listings(page_number = 1)
    request = EbayTrader::Request.new('GetMyeBaySelling') do
      # DetailLevel 'ReturnAll'
      DetailLevel 'ItemReturnAttributes'
      DetailLevel 'ItemReturnDescription'
      ActiveList do
        Include true
        Sort 'TimeLeft'
        Pagination do
          EntriesPerPage 200
          PageNumber page_number
        end
      end
    end

    more_results = []

    if request.response_hash[:active_list][:pagination_result]
      total_pages = request.response_hash[:active_list][:pagination_result][:total_number_of_pages]
      more_results = mass_listings(page_number + 1) if page_number < total_pages
    end

    if request.response_hash[:active_list] && request.response_hash[:active_list][:item_array]
      return request.response_hash[:active_list][:item_array][:item] + more_results
    else
      return [] + more_results
    end
  end

  def inactive_unsold_listings(page_number = 1)
    request = EbayTrader::Request.new('GetMyeBaySelling') do
      DetailLevel 'ReturnAll'
      UnsoldList do
        Include true
        Sort 'EndTime'
        DurationInDays 14
        Pagination do
          EntriesPerPage 200
          PageNumber page_number
        end
      end
    end

    if request.response_hash[:unsold_list][:pagination_result]
      items = Array(request.response_hash[:unsold_list][:item_array][:item])
      items.each do |item|
        next unless (product = C::Product::Variant.find_by(item_id: item[:item_id].to_s))
        puts "setting #{product.name} to inactive"
        product.update(status: :inactive, published_web: false)
      end
      total_pages = request.response_hash[:unsold_list][:pagination_result][:total_number_of_pages]
      inactive_unsold_listings(page_number + 1) if page_number < total_pages
    end
  end

  def inactive_sold_listings(page_number = 1)
    request = EbayTrader::Request.new('GetMyeBaySelling') do
      DetailLevel 'ReturnAll'
      SoldList do
        Include true
        Sort 'EndTime'
        DurationInDays 14
        Pagination do
          EntriesPerPage 200
          PageNumber page_number
        end
      end
    end

    if request.response_hash[:sold_list][:pagination_result]
      process_sold_listings(request.response_hash[:sold_list])
      total_pages = request.response_hash[:sold_list][:pagination_result][:total_number_of_pages]
      inactive_sold_listings(page_number + 1) if page_number < total_pages
    end
  end

  def process_sold_listings(sold_list)
    to_array(sold_list[:order_transaction_array][:order_transaction]).each do |transaction|
      if transaction[:order].present?
        to_array(transaction[:order][:transaction_array][:transaction]).each do |sold_listing|
          set_variant_to_inactive(sold_listing)
        end
      else
        to_array(transaction[:transaction]).each do |sold_listing|
          set_variant_to_inactive(sold_listing)
        end
      end
    end
  end

  def set_variant_to_inactive(sold_listing)
    return unless (product = C::Product::Variant.find_by(item_id: sold_listing[:item][:item_id].to_s))
    if sold_listing[:item][:quantity_available].present?
      product.update(current_stock: sold_listing[:item][:quantity_available])
    else
      product.inactive!
      product.update(current_stock: 0)
    end
  end

  def inactive_from_ebay
    item_ids = mass_listings.map { |m| m[:item_id].to_s }
    item_ids = C::Product::Variant.pluck(:item_id) - item_ids
    item_ids.each do |item_id|
      if product = C::Product::Variant.find_by(item_id: item_id)
        product.inactive!
        product.update(current_stock: 0)
      end
    end
  end

  def create_from_item_ids
    item_ids = mass_listings.map { |m| m[:item_id].to_s }
    item_ids -= C::Product::Variant.pluck(:item_id)
    item_ids.map do |item_id|
      build_local_ebay(get_item(obj: item_id), true)
    end
  end

  def create_from_ebay
    listings = to_array(mass_listings)
    listings.each do |listing|
      local_listing = C::Product::Variant.find_by(item_id: listing[:item_id])
      if local_listing.nil?
        listing = get_item(obj: listing[:item_id])
        build_local_ebay(listing)
      end
    end
  end

  def create_from_ebay_uk
    listings = to_array(mass_listings)
    listings.each do |listing|
      local_listing = C::Product::Variant.find_by(item_id: listing[:item_id])
      next unless local_listing.nil?
      if listing[:selling_status][:current_price].currency.iso_code == 'GBP'
        listing = get_item(obj: listing[:item_id])
        build_local_ebay(listing)
      end
    end
  end

  # skipping to correct page/date range based on products already created
  def skip_processed_pages(count=C::Product::Variant.count, time_from=(Time.now - 119.days), time_to=Time.now)
    product_count = count
    processed_pages_count = (product_count / 200).round

    # return entries in this block given page number outside of block range
    entries_for_block = request_get_seller_list(1, time_from, time_to)
    entries_for_block = entries_for_block.response_hash[:pagination_result][:total_number_of_entries]

    return if entries_for_block.zero? || entries_for_block.blank?

    if product_count > entries_for_block
      product_count -= entries_for_block
      skip_processed_pages(product_count, (time_from - 119.days), time_from)
    else
      request_all_listings((processed_pages_count.zero? ? 1 : processed_pages_count), time_from, time_to)
    end
  end

  # Only grabs first page from pagination result
  def listings_one_page_limit
    request_all_listings(1, Time.now - 119.days, Time.now, false, false)
  end

  def request_get_seller_list(page_number=1, time_from=(Time.now - 119.days), time_to=Time.now)
    EbayTrader::Request.new('GetSellerList') do
      DetailLevel 'ReturnAll'
      StartTimeFrom time_from.iso8601
      StartTimeTo time_to.iso8601
      Pagination do
        EntriesPerPage 200
        PageNumber page_number
      end
    end
  end

  # Creating products from entire eBay inventory
  # Using 119 days as date range because not sure how rigid eBay is on 120 days
  # Loops through all pages from eBay and then steps back 119 days and tries
  # to go through them all until a 119 day range has no listings
  def request_all_listings(page_number=1, time_from=(Time.now - 119.days), time_to=Time.now, iterate=true, paginate=true)
    request = request_get_seller_list(page_number, time_from, time_to)

    # stop if there is nothing
    return if request.response_hash[:pagination_result][:total_number_of_pages].zero?

    # process this page
    total_pages = request.response_hash[:pagination_result][:total_number_of_pages]
    process_listings_page(request.response_hash[:item_array])

    # get more pages or step back another date block
    if page_number == total_pages && iterate
      request_all_listings(1, (time_from - 119.days), time_from)
    elsif page_number != total_pages && paginate
      request_all_listings(page_number + 1, time_from, time_to)
    end
  end

  # Passing off the listing hash from eBay to either sync or build method in the
  # ebay_product_pull.rb
  # Limits it to only active eBay listings
  def process_listings_page(active_list)
    to_array(active_list[:item]).each do |listing|
      next unless listing[:selling_status][:listing_status] == 'Active'

      if !C::Product::Variant.find_by(item_id: listing[:item_id]) && !C::Product::Variant.find_by(sku: listing[:item_id]) 
        build_local_ebay(listing, true) 
      end
    end
  end

  def build_and_sync_job
    C::BackgroundJob.process('Ebay: Build and Sync Listings') do
      build_recent_listings
    end
  end

  # Builds products for active listings published on eBay in the last day
  # and then syncs any extra details, pushes data up to eBay (such as shop wrap)
  # and then creates product categories and categorizations
  def build_recent_listings(time_from=(Time.now - 1.day), time_to=Time.now, limit=nil)
    request_all_listings(1, time_from, time_to, false, true)
    process_recent_unsynced_listings(limit)
  end

  # sort of duplicated version to only take one arg to deal with rake task params
  def build_day_old_listings_and_sync(limit=nil)
    request_all_listings(1, (Time.now - 1.day), Time.now, false, true)
    process_recent_unsynced_listings(limit)
  end

  # and then syncs any extra details, pushes data up to eBay (such as shop wrap)
  # and then creates product categories and categorizations
  def process_recent_unsynced_listings(limit=nil)
    categories_dict = store_categories_dict

    # conditionally building store_categories based on ebay_store_categories
    build_store_categories(categories_dict) if C.build_ebay_store_categories

    master_ids = C::Product::Channel::Ebay.where(last_sync_time: nil).where.not(ended: true).pluck(:master_id)
    sync_and_revise_listings(C::Product::Master.where(id: master_ids), limit)
  end

  def resync_and_revise_unsuccessful
    masters1 = C::Product::Variant.where(status: :active).where(ebay_last_push_success: false).pluck(:master_id)
    masters2 = C::Product::Channel::Ebay.where.not(ended: true).pluck(:master_id)
    master_ids = masters1 & masters2
    sync_and_revise_listings(C::Product::Master.where(id: master_ids))
  end

  def sync_and_revise_listings(masters, limit=nil)
    masters.each_with_index do |master, i|
      return if limit.present? && i >= limit.to_i
      sync_product(obj: master)
      next if master.ebay_channel.ended
      revise_product(obj: master)
    end
  end

  def recategorise_products_without_categories
    categories_dict = store_categories_dict
    build_store_categories(categories_dict) if C.build_ebay_store_categories

    masters = C::Product::Master.left_joins(:categorizations).group(:id).where('c_product_masters.id NOT IN (SELECT product_id FROM c_product_categorizations)').order(id: :desc)

    masters.each do |master|
      sync_product(obj: master)
    end

  end

  # Creates product categories based on the ancestry of a product's eBay category
  # then it creates relevant categorizations for the product
  def categorize_synced_product(master)
    create_product_category(master.ebay_channel.ebay_category)
    create_product_categorizations(master)
  end
end

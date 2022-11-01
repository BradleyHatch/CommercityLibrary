# frozen_string_literal: true

require 'money'

module Ebay
  class Listing
    attr_reader :listing

    def initialize(listing_hash)
      @listing = listing_hash
    end

    # Listing essentials and siuch
    def item_id
      @listing[:item_id]
    end

    def sku
      @listing[:sku]
    end

    def mpn
      @listing[:mpn]
    end

    def body
      return unless (listing = @listing[:description])
      C.ebay_body_sub.each do |k, v|
        listing = listing.gsub(k, v)
      end
      listing
    end

    def condition_id
      @listing[:condition_id]
    end

    def condition_description
      @listing[:condition_description]
    end

    def country
      @listing[:country]
    end

    def dispatch_time
      @listing[:dispatch_time_max]
    end

    def duration
      @listing[:listing_duration]
    end

    def pickup_in_store_details
      @listing[:pickup_in_store_details]
    end

    def postcode
      @listing[:postal_code]
    end

    def primary_category_id
      @listing[:primary_category][:category_id]
    end

    def has_store_front?
      @listing[:storefront].present?
    end

    def store_category_id
      @listing[:storefront][:store_category_id].to_s
    end

    def store_category2_id
      @listing[:storefront][:store_category2_id].to_s
    end

    def returns_policy
      @listing[:return_policy]
    end

    def returns_accepted
      return returns_policy[:returns_accepted_option] == 'ReturnsAccepted' if returns_policy
      false
    end

    def sub_title
      @listing[:sub_title]
    end

    def title
      @listing[:title]
    end

    # Quantity related things
    def stock
      @listing[:quantity]
    end

    def sold
      @listing[:selling_status][:quantity_sold]
    end

    def computed_stock
      stock - sold
    end

    # Price related things
    def current_price
      @listing[:selling_status][:current_price]
    end

    def payment_methods
      @listing[:payment_methods]
    end

    # Shipping related things
    def shipping_details
      @listing[:shipping_details]
    end

    def domestic_options
      shipping_details[:shipping_service_options]
    end

    def international_options
      shipping_details[:international_shipping_service_option]
    end

    def no_shipping_options?
      domestic_options.blank? && international_options.blank?
    end

    def default_ship_tos
      @listing[:ship_to_locations]
    end

    def package_details
      @listing[:shipping_package_details]
    end

    # Product listing details (EAN, MPN, etc.) relating things
    def product_details
      @listing[:product_listing_details]
    end

    # Image related things
    def picture_urls
      @listing[:picture_details][:picture_url]
    end

    # Item specifics
    def item_specifics
      @listing[:item_specifics]
    end

    def name_value_list
      item_specifics[:name_value_list] if item_specifics.present?
    end

    # Listing details things
    def listing_details
      @listing[:listing_details]
    end

    def has_public_messages
      listing_details[:has_public_messages]
    end
  end
end

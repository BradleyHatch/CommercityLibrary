# frozen_string_literal: true

module EbayOfferPull
  extend ActiveSupport::Concern

  def get_offers(page_number = 1)
    request = EbayTrader::Request.new('GetBestOffers') do
      WarningLevel 'High'
      Pagination do
        EntriesPerPage 200
        PageNumber page_number
      end
    end

    C::Product::Offer.update_all(status: :resolved)

    if request.response_hash[:item_best_offers_array][:item_best_offers]
      (to_array request.response_hash[:item_best_offers_array][:item_best_offers]).each do |item_offer|
        item = item_offer[:item]
        next unless (item_offer[:role] = 'Seller')
        (to_array item_offer[:best_offer_array][:best_offer]).each do |offer|
          next unless (variant = C::Product::Variant.find_by(item_id: item[:item_id]))
          c_offer = variant.offers.find_or_create_by(offer_id: offer[:best_offer_id])
          c_offer.update!(
            price_pennies: (offer[:price] * 100).to_i,
            price_currency: offer[:price].currency,
            quantity: offer[:quantity],
            sender_email: offer[:buyer][:email],
            status: :pending,
            source: :ebay,
            sender_id: offer[:buyer][:user_id]
          )
        end
      end
    end

    if request.response_hash[:pagination_result]
      total_pages = request.response_hash[:pagination_result][:total_number_of_pages]
      get_offers(page_number + 1) if page_number < total_pages
    end
  end
end

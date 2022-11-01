# frozen_string_literal: true

C::Order::Item.class_eval do
  def delist_when_zero
    return if !C.delist_when_zero || product.blank? || product.item_id.blank?
    response_hash = C::EbayJob.perform_now('end_listing', product.item_id)
    product.ebay_channel.update(ended: true) if product.ebay_channel && response_hash[:ack] != 'Failure'
  end
end

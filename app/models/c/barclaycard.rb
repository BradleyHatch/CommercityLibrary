# frozen_string_literal: true

module C
  class Barclaycard
    class << self
      def live?
        ENV['BARCLAYCARD_LIVE_INT']&.to_i == 1
      end

      def submit_path
        if live?
          'https://payments.epdq.co.uk/ncol/prod/orderstandard.asp'
        else
          'https://mdepayments.epdq.co.uk/ncol/test/orderstandard.asp'
        end
      end

      def cart_from_param(str)
        ::C::Cart.find_by(id: str.to_s.split('-')[0].to_s.gsub(/\AC/, ''))
      end

      def form_data_for_cart(cart)
        sha = ENV['BARCLAYCARD_SHA_IN']
        data = unsigned_form_data_for_cart(cart).sort.reject { |_k, v| v.blank? }
        signature = Digest::SHA1.hexdigest data.map { |k, v| "#{k}=#{v}#{sha}" }.join
        data.to_h.merge(SHASIGN: signature)
      end

      def unsigned_form_data_for_cart(cart)
        {
          # Order Details
          AMOUNT: cart.price.fractional,
          CURRENCY: cart.price.currency.iso_code,
          LANGUAGE: 'en_US',
          ORDERID: "C#{cart.id}-#{Time.current.strftime('%H%M%S')}",
          PSPID: ENV['BARCLAYCARD_PSPID'],

          # Customer Details
          CN: cart.order.customer.name,
          EMAIL: cart.order.customer.email,
          OWNERADDRESS: cart.order.shipping_address.short_address,
          OWNERCTY: cart.order.shipping_address.country.name,
          OWNERTELNO: cart.order.customer.phone,
          OWNERTOWN: cart.order.shipping_address.city,
          OWNERZIP: cart.order.shipping_address.postcode,

          # Page Details
          TP: C.absolute_url('cart/checkout/barclaycard_ext'),
          ACCEPTURL: C.absolute_url('cart/checkout/barclaycard_return'),
          DECLINEURL: C.absolute_url('cart/checkout/barclaycard_return'),
          EXCEPTIONURL: C.absolute_url('cart/checkout/barclaycard_return'),
          CANCELURL: C.absolute_url('cart/checkout/barclaycard_return')
        }
      end

      def valid_signature?(data)
        data = data.map { |k, v| [k.to_s.upcase, v] }.reject { |_k, v| v.blank? }.to_h
        sha = ENV['BARCLAYCARD_SHA_OUT']
        signature = data.delete('SHASIGN').to_s
        digest = Digest::SHA1.hexdigest(data.sort.map { |k, v| "#{k}=#{v}#{sha}" }.join)
        digest.casecmp(signature).zero?
      end
    end
  end
end

# frozen_string_literal: true

module C
  module Product
    class PriceMatch < ApplicationRecord
      enum competitor: [
        'GAK',
        'Andertons',
        'Gear4music',
        'PMT',
        'Guitarguitar',
        'Reidys',
        'Absolute Guitars'
      ]

      belongs_to :variant, class_name: 'C::Product::Variant'

      monetize :price_pennies

      def display_price
        return '<div></div>' unless variant
        if price < variant.price * 1.01 && price > variant.price * 0.99
          "<div>£#{price}</div>"
        elsif price > variant.price
          "<div class=success_data>£#{price}</div>"
        else
          "<div class=error_data>£#{price}</div>"
        end
      end

      def display_last_updated
        if updated_at
          if updated_at != created_at
            if updated_at > Time.zone.now - 1.day
              "<div>Last Updated: #{updated_at.to_formatted_s(:short)}</div>"
            else
              "<div class=error_data>Last Updated: #{updated_at.to_formatted_s(:short)}</div>"
            end
          elsif updated_at < Time.zone.now - 1.hour
            '<div class=error_data>Not Yet Updated</div>'
          else
            '<div>Not Yet Updated</div>'
          end
        else
          '<div></div>'
        end
      end
    end
  end
end

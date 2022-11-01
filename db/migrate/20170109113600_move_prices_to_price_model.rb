# frozen_string_literal: true
class MovePricesToPriceModel < ActiveRecord::Migration[5.0]
  def up
    add_reference :c_product_variants, :web_price
    add_reference :c_product_variants, :amazon_price
    add_reference :c_product_variants, :ebay_price
    add_reference :c_product_variants, :retail_price

    # Check
    # [3, 1351, 12588, 6033, 10096, 236, 9196, 10435, 11026, 678, 12589]

    query = C::Product::Variant.where('updated_at >= ?', 3.days.ago)
    query = query.or(C::Product::Variant.active)
    total = query.count
    padding = [Math.log10(total), 0].max.to_i + 1

    query.each_with_index do |v, i|
      # Status
      name = v.name.present? ? v.name : 'Not named'
      print (' ' * 115) + "\r"
      print " (#{(i + 1).to_s.rjust(padding)}/#{total}) #{name[0..80]}...\r"
      $stdout.flush

      master = C::Product::Master.find_by(main_variant_id: v.id)

      if v.includes_tax?
        to_price_pennies = :with_tax_pennies
        to_price_currency = :with_tax_currency
      else
        to_price_pennies = :without_tax_pennies
        to_price_currency = :without_tax_currency
      end

      web_channel = C::Product::Channel::Web.find_by(master_id: master.id)
      unless web_channel.current_price_pennies.nil? || web_channel.current_price_pennies == 0
        begin
          v.update!(web_price: C::Price.create!(
            to_price_pennies => web_channel.current_price_pennies,
            to_price_currency => web_channel.current_price_currency,
            tax_rate: master.tax_rate
          ))
        rescue
          nil
        end
      end

      amazon_channel = C::Product::Channel::Amazon.find_by(master_id: master.id)
      unless amazon_channel.current_price_pennies == 0
        v.update!(amazon_price: C::Price.create!(
          to_price_pennies => amazon_channel.current_price_pennies,
          to_price_currency => amazon_channel.current_price_currency,
          tax_rate: master.tax_rate
        ))
      end

      ebay_channel = C::Product::Channel::Ebay.find_by(master_id: master.id)
      unless ebay_channel.start_price_pennies == 0
        v.update!(ebay_price: C::Price.create!(
          to_price_pennies => ebay_channel.start_price_pennies,
          to_price_currency => ebay_channel.start_price_currency,
          tax_rate: master.tax_rate
        ))
      end

      v.update!(retail_price: C::Price.create!(
        to_price_pennies => v.retail_price_pennies,
        to_price_currency => v.retail_price_currency,
        tax_rate: master.tax_rate
      ))
    end

    remove_monetize :c_product_variants, :shop_price
    remove_monetize :c_product_variants, :amazon_price
    remove_monetize :c_product_variants, :ebay_price
    remove_monetize :c_product_variants, :retail_price
    remove_column :c_product_variants, :includes_tax
  end

  def down
    add_monetize :c_product_variants, :shop_price
    add_monetize :c_product_variants, :amazon_price
    add_monetize :c_product_variants, :ebay_price
    add_monetize :c_product_variants, :retail_price
    add_column :c_product_variants, :includes_tax, :boolean, default: true

    C::Product::Variant.all.each do |v|
      v.update!(
        includes_tax: true,
        retail_price_pennies: v.retail_price.with_tax_pennies,
        retail_price_currency: v.retail_price.with_tax_currency,
        amazon_price_pennies: v.amazon_price.with_tax_pennies,
        amazon_price_currency: v.amazon_price.with_tax_currency,
        ebay_price_pennies: v.ebay_price.with_tax_pennies,
        ebay_price_currency: v.ebay_price.with_tax_currency,
        shop_price_pennies: v.web_price.with_tax_pennies,
        shop_price_currency: v.web_price.with_tax_currency
      )

      C::Product::Master.find_by(main_variant_id: v.id).update!(tax_rate: v.retail_price.tax_rate)
    end

    remove_reference :c_product_variants, :web_price
    remove_reference :c_product_variants, :amazon_price
    remove_reference :c_product_variants, :ebay_price
    remove_reference :c_product_variants, :retail_price
  end
end

# frozen_string_literal: true

module C
  class ComparePrices < ApplicationJob
    queue_as :default
    require 'nokogiri'

    def perform(*args)
      product_id = args.first
      product = C::Product::Variant.find(product_id)
      competitors = product.price_matches
      unless competitors.any?
        logger.info 'Product Variant has no Price Matches' unless Rails.env.test?
        return true
      end

      C::BackgroundJob.process('Update Price Matches') do
        failures = []
        skips = []

        logger.info '    ' if Rails.env.test?

        page = nil

        competitors.find_each(batch_size: 1) do |competitor|
          if (Time.zone.now - competitor.updated_at < 1.day) && !competitor.price.zero?
            skips << competitor
          else
            failed = false
            if Rails.env.test?
              logger.info '.'
            else
              logger.info "Checking \"#{competitor.url}\""
            end
            begin
              page = Nokogiri::HTML(open(competitor.url))
              case competitor.competitor
              when 'GAK'
                # good
                price = page.at_css('.gak-price').text[1..-1].delete(',')
              when 'Andertons'
                # good
                price = page.at_css('.product-price').text[1..-1].delete(',')
              when 'Gear4music'
                # good
                price = page.at_css('.c-val').text.delete(',')
              when 'PMT'
                # good
                price = if (special_price = page.at_css('.special-price'))
                          special_price.at_css('.price').text[1..-1].delete(',')
                        else
                          page.at_css('.regular-price').at_css('.price').text[1..-1].delete(',')
                        end
              when 'Guitarguitar'
                price = page.at_css('.price').text[1..-1].delete(',')
              when 'Reidys'
                price = page.at_css('.view_price_web').text[1..-1].delete(',')
              when 'Absolute Guitars'
                price = page.at_css('#_EKM_PRODUCTPRICE').text.delete(',')
              else
                failures << competitor
                failed = true
              end
            rescue
              failures << competitor
              failed = true
            end
            unless failed
              competitor.update(updated_at: Time.zone.now)
              unless competitor.update(price: price)
                failures << competitor
                true
              end
            end
          end
        end

        logger.info '' if Rails.env.test?

        if failures.any?
          if failures.size == 1
            logger.info 'There was 1 failed Price-Lookup:'
          else
            logger.info "There were #{failures.size} failed Price-Lookups:"
          end
          failures.each do |failure|
            logger.info "#{failure.competitor} (#{failure.url})"
          end
        end
        return true unless (failures.size == competitors.size - skips.size) && failures.any?
        false
      end
    end
  end
end

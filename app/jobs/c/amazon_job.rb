# frozen_string_literal: true

require 'peddler'
require 'amazon/result'

module C
  class AmazonJob < ApplicationJob
    queue_as :default

    XSD_PATH = File.join(C::Engine.root, 'app', 'assets', 'xsds')
    IMAGE_TYPES = ['Main'] + ((1..8).map { |i| "PT#{i}" })
    COLOR_MAP_REGEX = /beige|black|blue|brass|bronze|brown|chrome|clear|gold|gray|green|multi-coloured|natural|orange|pink|purple|red|silver|sunburst|white|yellow/
    FLAT_CATEGORIES = %w[Clothing ClothingAccessories].freeze

    def submit_products(products, options = {})
      raise if products.empty?
      errors = []
      products_for_submission = []
      listings = []
      products.each do |product|
        begin
          listing = create_product_listing(product)
        rescue Mws::Errors::ValidationError => e
          errors << { product_id: product.id, message: [e.message] }
          nil
        else
          validation_errors = validate_product(listing)
          if validation_errors.present?
            errors << { product_id: product.id, message: validation_errors }
          end
          products_for_submission << product
          listings << listing
        end
      end

      feed = build_product_feed(listings, options.merge(products_built: true))

      logger.warn "Amazon validation errors: #{errors.count}" if errors.any?

      feed_id = feeds_client.submit_feed(feed.to_xml, '_POST_PRODUCT_DATA_').parse['FeedSubmissionInfo']['FeedSubmissionId']
      C::AmazonProcessingQueue.push(products_for_submission, feed_id, :product, feed.to_xml)
      feed_id
    end

    ## Prices

    def build_price_feed(products, _options = {})
      Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                           'xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd') do
          xml.Header do
            xml.DocumentVersion '1.01'
            xml.MerchantIdentifier feeds_client&.merchant_id
          end
          xml.MessageType 'Price'

          products.map.with_index do |product, product_index|
            price = product.price(channel: :amazon, fallback: :web)
            xml.Message do
              xml.MessageID (product_index + 1).to_s
              xml.OperationType 'Update'

              xml.Price do
                xml.SKU product.sku
                xml.StandardPrice price, 'currency' => price.currency.iso_code
              end
            end
          end # map
        end # envelope
      end # builder
    end

    def submit_prices(products, options = {})
      if products.any?
        feed = build_price_feed(products, options).to_xml
        feed_id = feeds_client.submit_feed(feed, '_POST_PRODUCT_PRICING_DATA_').parse['FeedSubmissionInfo']['FeedSubmissionId']
        begin
          C::AmazonProcessingQueue.push(products, feed_id, :price, feed)
        rescue => e
          logger.error e
          logger.error "Feed ID: #{feed_id}"
        end
        feed_id
      else
        logger.info 'No prices pushed'
      end
    end

    def build_image_feed(products, _options = {})
      Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                           'xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd') do

          xml.Header do
            xml.DocumentVersion '1.01'
            xml.MerchantIdentifier feeds_client&.merchant_id
          end
          xml.MessageType 'ProductImage'

          products.map.with_index do |product, product_index|
            product.amazon_channel.channel_images.ordered.limit(9).map.with_index do |image, index|
              message_id = ((product_index + 1) * 1_000) + index
              xml.Message do
                xml.MessageID message_id.to_s
                xml.OperationType 'Update'

                xml.ProductImage do
                  xml.SKU product.sku
                  xml.ImageType IMAGE_TYPES[index]
                  xml.ImageLocation image.image.image.url.sub(/https/i, 'http')
                end
              end
            end
          end # map
        end # envelope
      end # builder
    end

    def submit_images(products, options = {})
      images = products.map { |product| product.amazon_channel.channel_images.count }
      if images.flatten.sum.positive?
        feed = build_image_feed(products, options).to_xml
        feed_id = feeds_client.submit_feed(feed, '_POST_PRODUCT_IMAGE_DATA_').parse['FeedSubmissionInfo']['FeedSubmissionId']
        C::AmazonProcessingQueue.push(products, feed_id, :image, feed)
        feed_id
      else
        logger.info 'No images pushed'
      end
    end

    def submit_shipping(_products, _options = {})
      raise NotImplementedError, 'Use account settings for delivery!'
    end

    ## Inventory

    def build_inventory_feed(products, _options = {})
      Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                           'xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd') do
          xml.Header do
            xml.DocumentVersion '1.01'
            xml.MerchantIdentifier feeds_client&.merchant_id
          end
          xml.MessageType 'Inventory'

          products.map.with_index do |product, product_index|
            xml.Message do
              xml.MessageID (product_index + 1).to_s
              xml.OperationType 'Update'

              xml.Inventory do
                xml.SKU product.sku
                xml.Quantity get_product_stock(product)
              end
            end
          end # map
        end # envelope
      end # builder
    end

    def submit_inventory(products, options = {})
      if products.any?
        feed = build_inventory_feed(products, options).to_xml
        feed_id = feeds_client.submit_feed(feed, '_POST_INVENTORY_AVAILABILITY_DATA_').parse['FeedSubmissionInfo']['FeedSubmissionId']
        C::AmazonProcessingQueue.push(products, feed_id, :inventory, feed)
        feed_id
      else
        logger.info 'No inventories pushed'
      end
    end

    def build_product_feed(products, options = {})
      Nokogiri::XML::Builder.new do |xml|
        xml.AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                           'xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd') do
          xml.Header do
            xml.DocumentVersion '1.01'
            xml.MerchantIdentifier feeds_client&.merchant_id
          end
          xml.MessageType 'Product'

          products.each.with_index(1) do |product, index|
            xml.Message do
              xml.MessageID index.to_s
              xml.OperationType 'Update'
              xml << if options[:products_built]
                       product.doc.root.to_s
                     else
                       create_product_listing(product, options).doc.root.to_s
                     end
            end
          end
        end
      end
    end

    def create_product_listing(product, _options = {})
      amazon_product_type = product.amazon_channel.product_type ||
                            product.categories.detect do |cat|
                              cat.amazon_product_type.present?
                            end&.amazon_product_type
      amazon_category = amazon_product_type&.amazon_category

      if FLAT_CATEGORIES.include?amazon_category&.name
        flat_product_listing(product, amazon_category)
      else
        standard_product_listing(product, amazon_category)
      end
    end

    def flat_product_listing(product, amazon_category)
      master = product.master
      amazon_product_type = product.amazon_channel.product_type || product.categories.detect { |c| c.amazon_product_type.present? }&.amazon_product_type
      amazon_category = amazon_product_type&.amazon_category

      Nokogiri::XML::Builder.new do |xml|
        xml.Product do
          xml.SKU product.sku
          if product.barcode.present?
            xml.StandardProductID do
              xml.Type product.barcode.symbology&.upcase
              xml.Value product.barcode.value
            end
          end

          xml.Condition do
            xml.ConditionType 'New'
          end

          xml.DescriptionData do
            xml.Title product.name
            xml.Brand master.brand&.name
            xml.Description get_product_description(master)
            product.amazon_channel.bullet_points.limit(5).each do |point|
              xml.BulletPoint point.value
            end
            xml.Manufacturer master.manufacturer.name if master.manufacturer.present?
            xml.MfrPartNumber master.main_variant.mpn if master.main_variant.mpn.present?
            master.amazon_channel.amazon_browse_nodes.each do |node|
              xml.RecommendedBrowseNode node.node_id
            end
          end

          xml.ProductData do
            xml.send(amazon_category&.name&.camelize || 'MissingProductCategory') do
              xml.ClassificationData do
                props_for(amazon_product_type).each do |property|
                  value = product.property(property)&.value
                  if property == 'ColorSpecification'
                    c = product.property('Color')
                    unless c.nil? || c.value.blank?
                      xml.ColorSpecification do
                        xml.Color c.value
                        xml.ColorMap product.property('ColorMap')&.value || c.value.downcase.match(COLOR_MAP_REGEX)[0]
                      end
                    end
                  elsif property == 'CountryProducedIn' # Not in properties
                    xml.send(property, product.country_of_manufacture.name) unless product.country_of_manufacture.nil?
                  elsif property == 'ClothingType' # Not in properties
                    xml.send(property, amazon_product_type.name)
                  elsif value.present?
                    xml.send(property, value)
                  end
                end
              end
            end
          end
        end
      end
    end

    def standard_product_listing(product, amazon_category)
      master = product.master
      amazon_product_type = product.amazon_channel.product_type || product.categories.detect { |c| c.amazon_product_type.present? }&.amazon_product_type
      amazon_category = amazon_product_type&.amazon_category

      Nokogiri::XML::Builder.new do |xml|
        xml.Product do
          xml.SKU product.sku
          if product.barcode.present?
            xml.StandardProductID do
              xml.Type product.barcode.symbology&.upcase
              xml.Value product.barcode.value
            end
          end

          xml.Condition do
            xml.ConditionType 'New'
          end

          xml.DescriptionData do
            xml.Title product.name
            xml.Brand master.brand&.name
            xml.Description get_product_description(master)
            product.amazon_channel.bullet_points.limit(5).each do |point|
              xml.BulletPoint point.value
            end
            xml.Manufacturer master.manufacturer.name if master.manufacturer.present?
            xml.MfrPartNumber master.main_variant.mpn if master.main_variant.mpn.present?
            master.amazon_channel.amazon_browse_nodes.each do |node|
              xml.RecommendedBrowseNode node.node_id
            end
          end

          xml.ProductData do
            xml.send(amazon_category&.name&.camelize || 'MissingProductCategory') do
              xml.ProductType do
                xml.send(amazon_product_type&.name&.camelize || 'MissingProductType') do
                  props_for(amazon_product_type).each do |property|
                    value = product.property(property)&.value
                    if property == 'ColorSpecification'
                      c = product.property('Color')
                      unless c.nil? || c.value.blank?
                        xml.ColorSpecification do
                          xml.Color c.value
                          xml.ColorMap product.property('ColorMap')&.value || c.value.downcase.match(COLOR_MAP_REGEX)[0]
                        end
                      end
                    elsif property == 'CountryProducedIn' # Not in properties
                      xml.send(property, product.country_of_manufacture.name) unless product.country_of_manufacture.nil?
                    elsif value.present?
                      xml.send(property, value)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    def check_feed_status(feed_ids = nil, options = {})
      feed_ids ||= C::AmazonProcessingQueue.processing_jobs.limit(100).pluck(:feed_id)
      return false if feed_ids.empty?
      response = feeds_client.get_feed_submission_list(feed_submission_id_list: feed_ids)

      completed = []

      [response.parse['FeedSubmissionInfo']].flatten.each do |info|
        q = C::AmazonProcessingQueue.find_by(feed_id: info['FeedSubmissionId'])
        next if q.blank?
        if info['FeedProcessingStatus'] == '_DONE_'
          result = Amazon::Result.new(
            feeds_client.get_feed_submission_result(q.feed_id).parse
          )

          if result.error_count.positive?
            logger.info "Job (#{q.feed_id}, #{q.feed_type}) failed with #{result.success_count} success(es) and #{result.error_count} error(s)"
            logger.info "Message was:\n#{result.to_json}"
            completed.append(q.mark_failed(result.to_json))
          else
            logger.info "Job (#{q.feed_id}, #{q.feed_type}) complete with no errors!"
            completed.append(q.mark_complete)
          end
        else
          logger.info "#{q.feed_id}, #{q.feed_type}: #{info['FeedProcessingStatus']}"
        end
      end

      process_jobs(completed, options)
    end

    def feeds_client
      @feeds_client ||= MWS.feeds(
        merchant_id:             ENV['MWS_MERCHANT_ID'],
        aws_access_key_id:       ENV['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key:   ENV['AWS_SECRET_ACCESS_KEY'],
        primary_marketplace_id:  ENV['MWS_MARKETPLACE_ID'],
        auth_token:              ENV['MWS_CLIENT_TOKEN']
      )
    end

    def perform(*args)
      request, data, options = args
      send(request, data, options || {})
    end

    def validate_feed(f, filename)
      schema = Nokogiri::XML::Schema(File.open(File.join(XSD_PATH, filename)))
      schema.validate(Nokogiri::XML(f.to_xml))
    end

    def validate_product(p)
      validate_feed(p, 'Product.xsd')
    end

    def props_for(type)
      return [] if type.nil?
      type.amazon_product_attributes.order(created_at: :asc).pluck(:name)
    end

    def push_updated_inventory(_data = nil, options = {})
      C::BackgroundJob.process('Amazon: Stock Sync') do
        products = C::Product::Variant.where(has_been_pushed_to_amazon: true)
        submit_inventory(products, options) unless products.empty?
      end
    end

    def push_updated_products(_data = nil, options = {})
      return unless C::Setting.get(:amazon_sync)

      C::BackgroundJob.process('Amazon: Product Sync') do
        mark_published_products_as_pushed

        last_push_date = C::AmazonProcessingQueue.product.order(completed_at: :desc).first&.created_at || 1.week.ago
        updated_master_ids = C::Product::Master.where('c_product_masters.updated_at > ?', last_push_date).ids
        products = C::Product::Variant.where(published_amazon: true, master_id: updated_master_ids)
        submit_products(products, options) unless products.empty?
      end
    end

    def process_jobs(q_objects, options = {})
      q_objects.each do |q_object|
        next unless q_object.product?
        q_object.cache_product_results
        products = q_object.successful_products
        logger.info "Queuing follow-ups for #{q_object.feed_id}: #{products.count}/#{q_object.products.count} products"
        submit_prices(products, options)
        submit_images(products, options)

        # The following line will push the current stock to Amazon. This
        # effectively enables the item for sale.
        submit_inventory(products, options) unless C::Setting.get(:amazon_sync)
      end
    end

    def get_product_stock(product)
      price = product.price(channel: :amazon, fallback: :web)
      # Fees on Amazon are (usually) <15%, check taxes as well
      # (1 - 0.15) * (100 / 120.0)
      fee_factor = 0.708333
      would_sell_at_loss = (price * fee_factor) < product.cost_price
      if product.active? && product.published_amazon? && !would_sell_at_loss
        [product.current_stock, 0].max
      else
        0
      end
    end

    def mark_published_products_as_pushed
      C::Product::Variant.where(
        has_been_pushed_to_amazon: false, published_amazon: true, status: :active
      ).find_each { |product| product.update(has_been_pushed_to_amazon: true) }
    end

    def get_product_description(master)
      description = if master.amazon_channel.description.present?
                      master.amazon_channel.description
                    else
                      master.web_channel.description
                    end
      ActionController::Base.helpers.sanitize(description, tags: %w[b i u p br])
    end
  end
end

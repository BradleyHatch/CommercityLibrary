# frozen_string_literal: true

module C
  class DataTransfer < ApplicationRecord
    mount_uploader :file, C::FileUploader

    enum import_type: [:csv]

    validates :file, presence: true
    validate :import_at_cannot_be_in_the_past

    INDEX_TABLE = {
      'Name': {
        link: {
          name: { call: 'name' },
          options: '[object]'
        }
       },
      'File': {
        call: 'file.url.split(\'/\').last'
       },
      'Scheduled': { call: 'import_at' },
      'Created': { call: 'created_at' },
      '': {
        link: {
          name: {
            text: 'Delete?'
          },
          options: '[object]',
          method: :delete,
          data: {
            confirm: 'Are you sure?'
          }
        }
      }
    }.freeze

    def import_at_cannot_be_in_the_past
      if import_at.present? && import_at < Date.today
        errors.add(:import_at, "can't be in the past")
      end
    end

    def xml_table
      Hash.from_xml(file.read)
    end

    def self.def_first
      ActiveRecord::Base.connection.execute <<-SQL.squish
        CREATE OR REPLACE FUNCTION public.first_agg ( anyelement, anyelement )
        RETURNS anyelement LANGUAGE SQL IMMUTABLE STRICT AS $$
          SELECT $1;
        $$;

        DROP AGGREGATE IF EXISTS public.FIRST (anyelement);
        CREATE AGGREGATE public.FIRST (
          sfunc = public.first_agg,
          basetype = anyelement,
          stype = anyelement
        );
      SQL
    end
    def_first

    def self.csv_download master_ids
      cwave_host = Rails.env == "development" ? "/uploads/c/product/image/image/" : "https://#{ENV['S3_BUCKET']}.s3.amazonaws.com/uploads/c/product/image/image/"
      upc = C::Product::Barcode.symbologies['UPC']
      ean = C::Product::Barcode.symbologies['EAN']

      key_text = 'property_values.value'
      key_text = "upper(#{key_text})" if C.import_properties_upcase

      keys_sql = C::Product::PropertyKey.order(key: :asc).ids.map do |k|
        "STRING_AGG(DISTINCT #{key_text}, ', ') FILTER (WHERE property_values.property_key_id = #{k})"
      end

      status_enum = C::Product::Variant.statuses.map { |k, v| "WHEN #{v} THEN '#{k}' " }.join

      q = <<-SQL.squish
        SELECT
          variant.sku,
          CASE WHEN variant.main_variant THEN null ELSE FIRST(masters_variants.sku) FILTER (WHERE masters_variants.main_variant) END,
          variant.mpn,
          variant.name,
          FIRST(web_channel.description),
          FIRST(web_channel.features),
          FIRST(web_channel.specification),
          FIRST(round(retail_price.with_tax_pennies::decimal / 100, 2)),
          FIRST(round(web_price.with_tax_pennies::decimal / 100, 2)),
          FIRST(round(web_channel.discount_price_pennies::decimal / 100, 2)),
          round(variant.rrp_pennies::decimal / 100, 2),
          round(variant.cost_price_pennies::decimal / 100, 2),
          FIRST(round(ebay_price.with_tax_pennies::decimal / 100, 2)),
          FIRST(round(amazon_price.with_tax_pennies::decimal / 100, 2)),
          FIRST(barcodes.value) FILTER (WHERE symbology = #{upc}),
          FIRST(barcodes.value) FILTER (WHERE symbology = #{ean}),
          STRING_AGG(DISTINCT '#{cwave_host}' || images.id || '/' || images.image, ', '),
          FIRST(country.iso2),
          FIRST(brand.name),
          FIRST(manufacturer.name),
          STRING_AGG(DISTINCT categories.name, ', '),
          FIRST(web_channel.sub_title),
          variant.has_delivery_override,
          variant.delivery_override_pennies,
          CASE variant.status #{status_enum} END,
          variant.published_web,
          variant.published_ebay,
          variant.featured,
          variant.click_and_collect,
          variant.current_stock
          #{keys_sql.presence && ','}
          #{keys_sql.join(',')}
        FROM c_product_variants AS variant
        LEFT JOIN c_product_masters AS master ON master.id = variant.master_id
        LEFT JOIN c_product_variants AS masters_variants ON masters_variants.master_id = master.id
        LEFT JOIN c_product_channel_webs AS web_channel ON web_channel.master_id = master.id
        LEFT JOIN c_prices AS retail_price ON retail_price.id = variant.retail_price_id
        LEFT JOIN c_prices AS web_price ON web_price.id = variant.web_price_id
        LEFT JOIN c_prices AS ebay_price ON ebay_price.id = variant.ebay_price_id
        LEFT JOIN c_prices AS amazon_price ON amazon_price.id = variant.amazon_price_id
        LEFT JOIN c_countries AS country ON country.id = variant.country_of_manufacture_id
        LEFT JOIN c_brands AS brand ON brand.id = master.brand_id
        LEFT JOIN c_brands AS manufacturer ON manufacturer.id = master.manufacturer_id
        LEFT JOIN c_product_categorizations AS categorizations
          ON categorizations.product_id = master.id
        LEFT JOIN c_categories AS categories ON categories.id = categorizations.category_id
        LEFT JOIN c_product_images AS images ON images.master_id = master.id
        LEFT JOIN c_product_barcodes AS barcodes ON barcodes.variant_id = variant.id
        LEFT JOIN c_product_property_values AS property_values
          ON property_values.variant_id = variant.id
        WHERE master.id IN (?)
        GROUP BY variant.id
      SQL

      q = sanitize_sql([q, master_ids])
      rows = connection.execute(q).values

      if C.strip_html_on_csv_export
        rows = rows.map do |r|
          r[4] = ActionController::Base.helpers.strip_tags(r[4])
          r
        end
      end

      CSV.generate do |csv|
        csv << create_csv_headers
        rows.each { |row| csv << row }
      end
    end

    # returns list of variant/web channel attribute names for csv file headers
    def self.create_csv_headers
      arr = %w[sku main_variant_sku mpn name description features specification retail_price web_price previous_price
         rrp cost_price ebay_price amazon_price upc ean images country_of_manufacture brand manufacturer
         category sub_title has_delivery_override delivery_override_pennies status published_web published_ebay featured click_and_collect current_stock]

      arr += C::Product::PropertyKey.order(key: :asc).pluck(:key)
    end

    def parsed_file
      data = file.file.read
      data = data.force_encoding("utf-8")
      data = data.encode('UTF-8', :invalid => :replace, :undef => :replace)
      csv = CSV.parse(data, headers: true)
      csv.map { |row| row }
    end

    def results_hash(errors=false, images=false, page=nil)
      json = []

      rows = parsed_file
      rows = rows.reject { |r| r.to_h.values.uniq == [nil] }


      if page
        slice_start = page * 50
        slice_end = slice_start + 50
        rows = Array.wrap(rows.slice(slice_start, slice_end))
      end


      rows.each do |row|
        barcode_attributes = []
        %w[UPC EAN].each do |barcode|
          row_value = row[barcode.parameterize]
          if row_value.present?
            barcode_attributes << { value: row_value, symbology: barcode }
          end
        end

        # Find country of manufacture ID, but only check DB if necessary
        # nil if country does not exist
        com_code = row['country_of_manufacture']
        country_of_manufacture_id = if com_code.present?
                                      C::Country.find_by(iso2: com_code)&.id
                                    end

        product_attributes = {
          main_variant_attributes: {
            sku: row['sku']&.strip,
            mpn: row['mpn'],
            name: row['name'],
            rrp: row['rrp'],
            cost_price: row['cost_price'],
            status: row['status'],
            published_web: row['published_web'],
            published_ebay: row['published_ebay'],
            featured: row['featured'],
            click_and_collect: row['click_and_collect'],
            current_stock: row['current_stock'],
            delivery_override_pennies: row['delivery_override_pennies'],
            has_delivery_override: row['has_delivery_override'],
            country_of_manufacture_id: country_of_manufacture_id,
            retail_price_attributes: {
              with_tax: row['retail_price']
            },
            web_price_attributes: {
              with_tax: row['web_price']
            },
            ebay_price_attributes: {
              with_tax: row['ebay_price']
            },
            amazon_price_attributes: {
              with_tax: row['amazon_price']
            },
            barcodes_attributes: barcode_attributes
          },
          web_channel_attributes: {
            description: row['description'],
            features: row['features'],
            specification: row['specification'],
            sub_title: row['sub_title'],
            discount_price: row['previous_price']
          },
          main_variant_sku: row['main_variant_sku'],
        }

        if row['delivery_override_pennies'].blank?
          product_attributes[:main_variant_attributes].delete(:delivery_override_pennies)
        end

        # Find brand. Brand name is unique, so look up with that
        brand_name = row['brand']&.strip
        if brand_name.present?
          if (brand = C::Brand.where('name ILIKE ?', "#{brand_name}").first)
            product_attributes[:brand_id] = brand.id
          else
            product_attributes[:brand_attributes] = { name: brand_name }
          end
        end

        # Find manufacturer. Brand name is unique, so look up with that
        manufacturer_name = row['manufacturer']&.strip
        if manufacturer_name.present?
          if (manufacturer = C::Brand.where('name ILIKE ?', "#{manufacturer_name}").first)
            product_attributes[:manufacturer_id] = manufacturer.id
          else
            product_attributes[:manufacturer_attributes] = { name: manufacturer_name }
          end
        end
      
        # Find category. Name is unique, so look up with that
        # Seeing as category is a complex association, and that using the wrong
        # category can result in the front-end site showing the mistake, only
        # look for existing categories.
        category_names = row['category']
        if category_names.present?
          product_attributes[:category_ids] = []
          category_names.split(',').map(&:strip).each do |category_name|
            (category = C::Category.find_by(name: category_name))
            product_attributes[:category_ids] << category&.id
          end
        end

        product_attributes[:remote_image_array] = row['images'] if images

        product_attributes[:properties] = C::Product::PropertyKey.all.map do |k|
          next if !row[k.key]
          { value: row[k.key], key: k.id }
        end.compact


        master = C::Product::Master.new(product_attributes.except(:properties, :main_variant_sku))


        if master.valid? || master.errors.full_messages == ['Main variant sku has already been taken'] ||
           master.errors.full_messages == ['Main variant barcodes value has already been taken'] ||
           master.errors.full_messages == ['Main variant barcodes value has already been taken', 'Main variant sku has already been taken'] ||
           master.errors.full_messages == ["Images image could not download file: 403 Forbidden", "Images image can't be blank"] ||
           master.errors.full_messages == ["Main variant sku has already been taken", "Images image could not download file: 403 Forbidden", "Images image can't be blank"]
          json << product_attributes
        elsif errors
          json << { sku: master.sku,
                    error: master.errors.full_messages.join(', ') }
        end
      end
      json
    end

    def import!
      C::BackgroundJob.process('CSV Import',
                               self_destruct: true,
                               job_size: results_hash.count,
                               job_processed_count: 0) do |job|
        update(import_started_at: Time.zone.now)



        results_hash(false, true).each_with_index do |product_hash, i|

          C::DataTransfer.import_product_from_hash(product_hash, self)
          job.update!(job_processed_count: i + 1)
        end

        destroy!
      end
    end

    def self.import_product_from_hash(product_hash, record)

      clean_hash(product_hash)

      if product_hash[:brand_attributes].present?
        brand_name = product_hash[:brand_attributes][:name]

        brand = C::Brand.where('name ILIKE ?', "#{brand_name}").first
        
        if brand.present?
          product_hash[:brand_id] = brand.id
        else
          brand = C::Brand.create(name: brand_name)
          product_hash[:brand_id] = brand.id
        end
        product_hash.delete(:brand_attributes)
      end

      if product_hash[:manufacturer_attributes].present?
        manufacturer_name = product_hash[:manufacturer_attributes][:name]

        manufacturer = C::Brand.where('name ILIKE ?', "#{manufacturer_name}").first

        if manufacturer.present?
          product_hash[:manufacturer_id] = manufacturer.id
        else
          manufacturer = C::Brand.create(name: manufacturer_name)
          product_hash[:manufacturer_id] = manufacturer.id
        end
        product_hash.delete(:manufacturer_attributes)
      end

      barcodes_attributes = product_hash[:main_variant_attributes].delete(:barcodes_attributes)
      properties = product_hash.delete(:properties)
      main_variant_sku = product_hash.delete(:main_variant_sku)
      remote_image_array = product_hash.delete(:remote_image_array)


      if (variant = C::Product::Variant.find_by(sku: product_hash[:main_variant_attributes][:sku]))
        product_hash[:main_variant_attributes].delete(:sku)
        product_hash[:main_variant_attributes][:id] = variant.id
        product_hash[:web_channel_attributes][:id] = variant.web_channel.id

        if !variant.main_variant
          product_hash[:variants_attributes] = [product_hash[:main_variant_attributes]]
          product_hash.delete(:main_variant_attributes)
        end

        #TODO reject_if blank-

        variant.reload

        import_barcodes(barcodes_attributes || [], variant)
        import_properties(properties || [], variant)
        variant.master.update(product_hash)
        master = variant.master

        import_images(master, remote_image_array, record.replace_images) if master
      elsif main_variant_sku
        master = C::Product::Variant.find_by(sku: main_variant_sku).master
        variant = master.variants.create!(product_hash[:main_variant_attributes])
        import_barcodes(barcodes_attributes || [], variant)
        import_properties(properties || [], variant)
        import_images(master, remote_image_array, record.replace_images) if master
      else
        master = C::Product::Master.create!(product_hash)
        variant = master.main_variant
        import_barcodes(barcodes_attributes || [], master.main_variant) if master
        import_properties(properties || [], master.main_variant) if master
        import_images(master, remote_image_array, record.replace_images) if master
      end

      variant.build_cache_fields
      variant.build_cache_main_image

      if main_variant_sku
        old_master = master
        main_variant = C::Product::Variant.find_by(sku: main_variant_sku)
      
        if main_variant && main_variant.master_id != variant.master_id
          variant.update!(master_id: main_variant.master_id, main_variant: false)
          old_master.reload

          old_master.destroy! if old_master.variants.size == 0
        end
      end
    end

    def self.clean_hash(hash)
      hash.values.each do |v|
        clean_hash(v) if v.is_a?(Hash)
      end
      hash.compact!
    end

    def self.import_barcodes(barcodes, variant)
      barcodes.each do |barcode|
        next if C::Product::Barcode.exists?(symbology: barcode[:symbology], value: barcode[:value])
        b = variant.barcodes.find_or_initialize_by(symbology: barcode[:symbology])
        value = barcode[:value]
        if b.value != value
          b.value = value
          b.save!
        end
      end
    end

    def self.import_properties(properties, variant)
      properties.each do |obj|
        next if obj.nil? || obj[:value].blank? || obj[:key].blank?
        values = obj[:value].split(',')
        values.each do |new_value|
          variant.property_values.find_or_create_by(value: new_value.strip, property_key_id: obj[:key])
        end
      end
    end

    def self.import_images(master, remote_image_array, replace = false)
      begin
        if remote_image_array.present?
          if replace
            puts "REPLACE ALL IMAGES!!!!"
            master.images.destroy_all
          end

          master.update!(remote_image_array: remote_image_array)

          images_string = remote_image_array.gsub(/\s/, '')
          
          all_web_channel_images = master.web_channel.channel_images.to_a

          weight = 1
  
          images_string.split(',').map do |image|
            parts = image.split('/')
            filename = parts.last

            matching_web_channel_image = all_web_channel_images.find do |ci|
              ci.image['image'] == filename
            end

            if matching_web_channel_image.present?
              all_web_channel_images = all_web_channel_images - [matching_web_channel_image]
              matching_web_channel_image.update!(weight: weight)
              weight = weight + 1
            end
          end

          all_web_channel_images.each do |ci|
            ci.update!(weight: weight)
            weight = weight + 1
          end

        end
      rescue => e
        logger.error e.message
      end
    end
  end
end

# frozen_string_literal: true

module C
  class ImportData < ApplicationJob
    queue_as :default

    # IMPORT GUIDE 
    # IMPORT IN THIS ORDER

    #====
    # PRODUCTS
    #====
    ###   b_products_desc = bulk of the information for the product (id, name, titles, descriptions)
    ###   b_products = Stock, Price
    ###   products_description = barcode
    ###   b_mask
    ###   product_images

    #===
    # CATEGORIES
    #===
    ###   class = All categories
    ###   class_tree = Category Hierarchy

    ###   b_prod_class = Which category the product is in

    #===
    # BRANDS
    #===
    ###   manufacturers = NAME
    ###   manufacturers_info = URL

    ###   b_prod_class = Which category the product is in

    def b_products_desc
      @rows.each do |row|
        @hash = Hash[row['fieldname'].zip row['value']]
        logger.info "DESC starting #{@hash['products_id']}"
        next if Product::Variant.find_by(sku: @hash['products_id'])

        @master = Product::Master.new
        @variant = @master.build_main_variant(sku: @hash['products_id'])

        @variant.name = @hash['products_name']
        @variant.weight = @hash['products_weight']
        @variant.weight_unit = @hash['weight_unit']
        @variant.x_dimension = @hash['products_dim_x']
        @variant.y_dimension = @hash['products_dim_y']
        @variant.z_dimension = @hash['products_dim_z']
        @variant.description = "#{@hash['extended_name1']} #{@hash['products_description']} #{@hash['extended_description1']} #{@hash['extended_description2']} #{@hash['extended_description3']} #{@hash['extended_description4']}"

        @master.save

        @master.title = @hash['meta_title']
        @master.meta_description = @hash['meta_description']
        @variant.inactive!
      end
    end

    def b_products
      @byebug = false
      @rows.each do |row|
        @hash = Hash[row['fieldname'].zip row['value']]

        if (variant = Product::Variant.find_by(sku: @hash['products_id']))
          logger.info "importing #{@hash['products_id']} - price: #{@hash['products_price']} - stock: #{@hash['products_quantity']}"
          variant.retail_price.update!(without_tax: @hash['products_price']) if @hash['products_price'].present?
          stock = @hash['products_quantity'].to_i < 0 ? 0 : @hash['products_quantity'].to_i
          variant.current_stock = stock
          if !variant.retail_price.zero? && variant.current_stock != 0 && variant.name.present?
            variant.active!
          end
          variant.save!
          variant.update(updated_at: Time.zone.now, myriad_updated_at: Time.zone.now)
        else
          logger.info "not importing #{@hash['products_id']}"
        end
      end
    end

    def perform(*args)
      # BACK_JOBS: update that Myriad has succeeded
      C::BackgroundJob.process('Myriad: Stock Update') do
        data_import_id = args.first
        @data_transfer = DataTransfer.find(data_import_id)
        hash_table = Hash.from_xml(@data_transfer.file.read)
        @rows = hash_table['data']['rowdata']
        import_type = @data_transfer.file.path.split('/').last.split('.').first.gsub(/\d/, '')
        if @rows
          unless import_type == 'class' || import_type == 'class_tree'
            @rows = @rows
          end
          send(import_type) if @rows
        end
      end
    end
  end
end

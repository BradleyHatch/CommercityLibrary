# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Products
      class MastersController < AdminController
        require 'csv'
        before_action :get_live_ebay_status, only: :edit
        load_and_authorize_resource class: C::Product::Master
        skip_before_action :verify_authenticity_token, only: :product_image

        def get_live_ebay_status
          main_variant = C::Product::Variant.find_by(master_id: params[:id], main_variant: true)
          if (ENV['USE_EBAY_PRODUCT_PIPELINE'] && main_variant.ebay_product_pipeline_id)
            C::EbayPipeline.new(main_variant).status
          end
        end

        def index
          per_page = params[:per_page] || C.products_per_page
       
          if params[:q].present? 
            session[:cache_product_masters_q] = params[:q]
          end

          respond_to do |format|
            format.html do
              @masters = filter_and_paginate(
                params[:reduced_index] ? @masters.with_main_variant : @masters.with_includes, C.default_products_sort, per_page
              )
            end
            format.xml
          end
        end

        def cached_search_redirect
          new_params = {}

          if session[:cache_product_masters_q].present?
            new_params[:q] = session[:cache_product_masters_q]
            session[:cache_product_masters_q] = nil
          end
          
          redirect_to product_masters_path(new_params)
        end

        def edit
          @master.build_nested_elements
          if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
            @amazon_pipeline_message = @master.main_variant.amazon_product_pipeline_data["message"]
            @amazon_pipeline_error = @master.main_variant.amazon_product_pipeline_data["error"]
            @amazon_pipeline_logs = C::AmazonPipeline.logs(
              @master.variants.where.not(amazon_product_pipeline_id: nil)
            )
          else
            job = C::AmazonJob.new
            @amazon_validation_errors = job.validate_product(
              job.create_product_listing(@master.main_variant)
            )
            @amazon_return_errors = @master.amazon_processing_queues
              .product
              &.last
              &.failure_messages_for(@master)
          end

          respond_to do |format|
            format.html
            format.js { ajax_form }
          end
        end

        def new
          @master.build_main_fields
        end

        def create
          if @master.save
            redirect_to edit_product_master_path(@master),
                        notice: 'Product Created.'
          else
            render :new
          end
        end

        def update
          options_ids_next = (master_params["main_variant_attributes"]["option_ids"] || []).select(&:presence).map(&:to_i)

          options_are_bad = @master.main_variant.options_are_changing_but_they_on_a_cart(options_ids_next)

          if options_are_bad
            master_params_hash = master_params.to_h
            master_params_hash["main_variant_attributes"]["option_ids"] = @master.main_variant.option_ids
            @master.assign_attributes(master_params_hash)

            flash[:error] = "Can't update product - currently assigned options are in a cart"
            return render :edit
          end

          @master.assign_attributes(master_params)

          if %w[update upload].include? params[:commit]
            flash.now[:success] = 'Images Uploaded.'
            render :edit
          elsif @master.save
            @master.update(updated_at: Time.zone.now)

            # manually looping through the images attrs in the params to assign alt tags
            # because the master model has a weird rejection for accepted attributes
            # not entirely sure what it's used for so this is safer for now
            if master_params[:images_attributes]
              master_params[:images_attributes].each do |_, image_attrs|
                @master.images.find_by(id: image_attrs[:id])&.update(alt: image_attrs[:alt])
              end
            end

            case params[:commit]
            when 'Disable Product'
              @master.main_variant.update(status: :inactive, manually_disabled: true)
              @master.main_variant.sibling_variants.update_all(status: :inactive)
              @master.ebay_channel.set_to_inactive
            when 'Enable Product'
              @master.main_variant.update(status: :active, manually_disabled: false)
              @master.main_variant.sibling_variants.update_all(status: :active)
            when 'Remove from Featured Products'
              @master.main_variant.update(featured: false)
            when 'Feature Product'
              @master.main_variant.update(featured: true)
            when 'Stop selling on Website'
              @master.main_variant.update(published_web: false)
            when 'Sell on Web'
              @master.main_variant.update(published_web: true)
            when 'Stop selling on Amazon'
              @master.main_variant.update(published_amazon: false)
            when 'Sell on Amazon'
              @master.main_variant.update(published_amazon: true)
            when 'Stop selling on eBay'
              @master.main_variant.update(published_ebay: false)
              @master.ebay_channel.set_to_inactive
            when 'Sell on eBay'
              @master.main_variant.update(published_ebay: true)
            when 'Stop selling on Google'
              @master.main_variant.update(published_google: false)
            when 'Sell on Google'
              @master.main_variant.update(published_google: true)
            when 'Remove from Display Only'
              @master.main_variant.update(display_only: false)
            when 'Display Only'
              @master.main_variant.update(display_only: true)
            when 'Discontinue Product'
              @master.main_variant.update(discontinued: true)
            when 'Activate Product'
              @master.main_variant.update(discontinued: false)
            when 'Duplicate'
              redirect_to(new_duplicate_product_master_path(@master)) && return
            when 'Update Price Matches'
              C::ComparePrices.perform_later(@master.main_variant.id)
            when 'Auto assign new Barcode'
              barcode = C::Product::Barcode.unassigned.first
              @master.main_variant.barcodes.append(barcode) if barcode.present?
            end

            # calling method that should loop through each channel image and
            # assign their order
            weights

            if C::Setting.get(:ebay_sync) && @master.main_variant.published_ebay && @master.main_variant.active?
              if ENV['USE_EBAY_PRODUCT_PIPELINE']
                valid_for_ebay = @master.local_ebay_validate

                if valid_for_ebay
                  C::EbayPipeline.new(@master.main_variant).push
                else
                  flash[:error] = "Error validating product for eBay locally - please see eBay tab"
                end
              else
                C::EbayJob.perform_now('add_or_revise_variants', obj: @master)
              end
            end

            @master.set_related_from_csv(params[:related_product_csv], master_params[:related_product_ids]) if params[:related_product_csv]
            @master.set_related_from_csv(params[:add_on_product_csv], master_params[:add_on_ids], 'add_on_products', 'add_on_id') if params[:add_on_product_csv]

            if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
              C::AmazonPipeline.save_data(
                @master.variants.where(published_amazon: true),
                status: :pending,
                error: nil,
                message: "This product has been queued and will be pushed to Amazon shortly."
              )
              @master.amazon_channel.update!(last_push_success: nil)
            end

            if params[:ebay_upload]
              if ENV['USE_EBAY_PRODUCT_PIPELINE']
                valid_for_ebay = @master.local_ebay_validate

                if valid_for_ebay
                  C::EbayPipeline.new(@master.main_variant).push
                  flash[:success] = 'Product Updated.'
                else
                  flash[:error] = "Error validating product for eBay locally - please see eBay tab"
                end

                redirect_to edit_product_master_path(@master)
              else
                redirect_to ebay_confirm_product_master_path(
                  val: params[:ebay_upload]
                )
              end
            elsif params[:ebay_revise]
              if ENV['USE_EBAY_PRODUCT_PIPELINE']
                valid_for_ebay = @master.local_ebay_validate
                if valid_for_ebay
                  C::EbayPipeline.new(@master.main_variant).push
                  flash[:success] = 'Product Updated.'
                else
                  flash[:error] = "Error validating product for eBay locally - please see eBay tab"
                end
 
                redirect_to edit_product_master_path(@master)
              else
                redirect_to ebay_methods_product_master_path(
                  val: params[:ebay_revise]
                )
              end
            elsif params[:ebay_relist]
              redirect_to ebay_methods_product_master_path(
                val: params[:ebay_relist]
              )
            elsif params[:ebay_clear]
              redirect_to clear_ebay_item_id_product_master_path(
                val: params[:ebay_clear]
              )
            else
              flash[:success] = 'Product Updated.'
              redirect_to edit_product_master_path(@master)
            end
          else
            if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
              @amazon_pipeline_logs = C::AmazonPipeline.logs(
                @master.variants.where.not(amazon_product_pipeline_id: nil)
              )
            end
            render :edit
          end
        end

        def destroy
          @master.destroy!
          flash[:success] = 'Product Deleted.'
          redirect_to product_masters_path
        end

        def mass_assign
          ids = params[:ids]
          @objects = C::Product::Master.where(id: ids)
        end

        def assign_property_values
          ids = params[:ids]
          @objects = C::Product::Master.where(id: ids)
          @keys = C::Product::PropertyKey.all
        end

        def assign_property_values_update
          ids = params[:ids].split(' ').map(&:to_i)
          C::Product::Master.where(id: ids).each do |master|
            pv = master.property_values.find_or_initialize_by(
              property_key_id: params[:property_key_id]
            )
            pv.value = params[:value]
            pv.save!
          end

          redirect_to action: :index
        end

        def merge
          ids = params[:ids]
          @objects = C::Product::Master.where(id: ids)
        end

        def bulk_actions
          actions = params[:bulk_actions]
          products_ids = params[:master]
          case actions
          when 'category', 'collection', 'brand', 'manufacturer', 'shipping', 'country', 'product_voucher'
            redirect_to(mass_assign_product_masters_path(
                          ids: products_ids, bulk: actions
            )) && return
          when 'make_inactive'
            params[:master].each do |id|
              temp_master = C::Product::Master.find(id.to_i)
              temp_master.main_variant.inactive!
              temp_master.ebay_channel.set_to_inactive
            end
          when 'active'
            params[:master].each do |id|
              C::Product::Master.find(id.to_i).main_variant.active!
            end
          when 'discontinue'
            params[:master].each do |id|
              C::Product::Master.find(id.to_i).main_variant.update(discontinued: true)
            end
          when 'delete'
            flash[:notice] = "#{params[:master].size} products will be deleted shortly."
            Thread.new do
              if C.bulk_action_delete
                params[:master].each do |id|
                  C::Product::Master.find(id.to_i).destroy
                end
              end
            end
          when 'download_as_csv'
            send_data C::DataTransfer.csv_download(params[:master]),
                      type: 'text/csv; charset=iso-8859-1; header=present',
                      disposition: 'attachment; filename="product_csv.csv"'
            return
          when 'push_to_ebay'
            params[:master].each do |id|
              if ENV['USE_EBAY_PRODUCT_PIPELINE']
                C::EbayPipeline.new(C::Product::Master.find(id.to_i).main_variant).push
              else
                C::Product::Master.find(id.to_i).ebay_channel.push_to_ebay
              end
            end
          when 'push_to_amazon'
            C::Product::Variant.where(master_id: products_ids,
                                      main_variant: true).find_each do |product|
              product.update(published_amazon: true)
            end
            # Touch all masters to ensure they are pushed to Amazon
            C::Product::Master.where(id: products_ids).find_each do |product|
              product.update(updated_at: Time.zone.now)
            end
          when 'push_to_google'
            C::Product::Variant.where(master_id: products_ids,
                                      main_variant: true).find_each do |product|
              product.update(published_google: true)
            end
          when 'merge_masters'
            redirect_to(merge_product_masters_path(ids: products_ids)) && return
          when 'property_value'
            redirect_to(assign_property_values_product_masters_path(
                          ids: products_ids
            )) && return
          end
          redirect_to product_masters_path
        end

        def ebay_methods
          result = ''
          begin
            case params[:val]
            when 'add'
              if @master.main_variant.active? &&
                 @master.main_variant.published_ebay
                C::EbayJob.perform_now('add_or_revise_variants', obj: @master)
                result = @master.ebay_channel.error_logs('uploaded')
              else
                result = 'Product must be flagged to be published on eBay before upload'
              end
              redirect_to edit_product_master_path(@master)
            when 'revise'
              C::EbayJob.perform_now('add_or_revise_variants', obj: @master)
              result = @master.ebay_channel.error_logs('revised')
              redirect_to edit_product_master_path(@master)
            when 'sync_product'
              if ENV['USE_EBAY_PRODUCT_PIPELINE']
                C::EbayPipeline.new(@master.main_variant).pull
              else
                C::EbayJob.perform_now('sync_product', obj: @master)
                result = "#{@master.main_variant.name} was updated from eBay"
              end
              redirect_to edit_product_master_path(@master)
            when 'relist'
              C::EbayJob.perform_now('relist_product', @master)
              result = "#{@master.main_variant.name} has been been relisted"
              redirect_to edit_product_master_path(@master)
            end
          rescue => e
            result = 'There was a problem processing your request'
            Rails.logger.info e
            redirect_to edit_product_master_path(@master)
          end
          flash[:notice] = result unless result == ''
        end

        def ebay_confirm
          @ebay = @master.ebay_channel

          if !@master.main_variant.published_ebay
            redirect_to(edit_product_master_path(@master), notice: 'Product must be flagged to be published on eBay before upload')
            return nil
          end

          if @master.main_variant.item_id.present?
            redirect_to(edit_product_master_path(@master), notice: 'Product already has an eBay item ID')
            return nil
          end

          if @ebay.ebay_category_id.blank? && @ebay.category_fallback.blank?
            redirect_to(edit_product_master_path(@master), notice: 'eBay listing is missing a category')
            return nil
          end

          @call = params[:val]
          @result = C::EbayJob.perform_now('verify_product', obj: @master)

          if @result.blank?
            redirect_to(edit_product_master_path(@master), notice: 'Error with call to eBay. Try again in a few moments')
            return nil
          end
        end

        # Sets up instance variables for ebay_category.js.erb that renders
        # partial for adding/reloading eBay category select fields
        # Instance variables necessary for insane logic in the _ebay_categories
        # partial
        def ebay_category
          vars = C::EbayCategory.select_setup(params, @master.ebay_channel)
          @check = vars[:check]
          @save_name = vars[:save_name]
          @cats = vars[:cats] || []
          @inc = vars[:inc]
          @ebay_cat = vars[:ebay_cat]

          if @check == 'check' && @cats.empty? && (ebay_category = C::EbayCategory.find_by(category_name: C.default_ebay_category))
            @cats = ebay_category.self_and_ancestors.reverse
          end

          respond_to do |format|
            format.js do
              render 'c/admin/ebay_category'
            end
          end
        end

        def ebay_auto_sync
          @master = C::Product::Master.find(params[:id])
          if C.auto_ebay_sync && @master.main_variant.item_id.present?
            if ENV['USE_EBAY_PRODUCT_PIPELINE']
              C::EbayPipeline.new(@master.main_variant).pull
            else
              C::EbayJob.perform_now('sync_product', obj: @master)
              result = "#{@master.main_variant.name} was updated from eBay"
            end
          end
          redirect_to c.edit_product_master_path(@master)
        end

        def amazon_autocomplete
          product_type = C::AmazonProductType.find(params[:product_type_id])
          available_attrs = product_type.amazon_product_attributes.order(
            created_at: :asc
          ).map { |a| a.name.titlecase }

          respond_to do |format|
            format.json do
              render json: { available_properties: available_attrs }
            end
          end
        end

        def amazon_product_types
          category = C::AmazonCategory.find(params[:category_id])
          available_types = {}
          category.amazon_product_types
                  .order(created_at: :asc)
                  .pluck(:name, :id).map do |name, id|
            available_types[name.titlecase] = id
          end

          respond_to do |format|
            format.json do
              render json: { available_product_types: available_types }
            end
          end
        end

        def amazon_methods
          @master.upload_to_amazon
          flash[:success] = 'Amazon job queued'
          redirect_to @master
        end

        def property_values_autocomplete
          key = C::Product::PropertyKey.find(params[:key_id])
          available_attrs = key.property_values.pluck(:value).uniq

          respond_to do |format|
            format.json do
              render json: { available_values: available_attrs }
            end
          end
        end

        def create_channel_image
          channel = [params[:channel_type].to_sym] & [:amazon, :ebay, :web]
          @channel = @master.send("#{channel.join}_channel")
          @image = @channel.channel_images
                           .find_or_create_by(image_id: params[:image_id])
          respond_to do |format|
            format.html { redirect_to edit_product_master_path(@master) }
            format.js do
              @channel_type = params[:channel_type]
            end
          end
        end

        def destroy_channel_image
          channel = [params[:channel_type].to_sym] & [:amazon, :ebay, :web]
          @channel = @master.send("#{channel.join}_channel")
          @channel_image = @channel.channel_images
                                   .find_by(id: params[:channel_image_id])
          @image = @master.images.find_by(id: @channel_image&.image_id)
          @channel_image&.destroy
          respond_to do |format|
            format.html { redirect_to edit_product_master_path(@master) }
            format.js do
              @channel_type = params[:channel_type]
            end
          end
        end

        # dropzone product image methods
        def product_image
          @master.touch
          @master.variants.find_each(&:touch)
          @master.images.create(image: params[:file])
        end

        def destroy_image
          @master.touch
          @master.variants.find_each(&:touch)
          @master.images.find_by(id: params[:image_id])&.destroy
          respond_to do |format|
            format.js
          end
        end

        def reload_images
          respond_to do |format|
            format.js
          end
        end

        def mass_assign_update
          ids = params[:ids].split(' ').map(&:to_i)

          case params[:bulk]

          when 'category'
            if (@category = C::Category.find_by(id: params[:val]))
              C::Product::Master.where(id: ids).each do |product|
                product.categorise @category
              end
            end
          when 'collection'
            if (@collection = C::Collection.find_by(id: params[:val]))
              C::Product::Master.where(id: ids).each do |product|
                product.main_variant.collection_variants.find_or_create_by(collection_id: @collection.id)
              end
            end
          when 'brand'
            if (@brand = C::Brand.find_by(id: params[:val]))
              C::Product::Master.where(id: ids).find_each do |product|
                product.update(brand_id: @brand.id)
              end

            end
          when 'manufacturer'
            if (@brand = C::Brand.find_by(id: params[:val]))
              C::Product::Master.where(id: ids).find_each do |product|
                product.update(manufacturer_id: @brand.id)
              end

            end
          when 'shipping'
            if (@brand = C::Brand.find_by(id: params[:val]))
              C::Product::Master.where(id: ids).each do |master|
                master.main_variant.update(delivery_override: params[:val])
                master.variants.each do |v|
                  v.update(delivery_override: params[:val])
                end
              end
            end
          when 'country'
            if (@country = C::Country.find_by(id: params[:val]))
              C::Product::Master.where(id: ids).each do |master|
                master.main_variant.update(country_of_manufacture_id: params[:val])
                master.variants.each do |v|
                  v.update(country_of_manufacture_id: params[:val])
                end
              end

            end
          when 'product_voucher'
            if (@product_voucher = C::Product::Voucher.find_by(id: params[:val]))
              @product_voucher.update(restricted: true)
              C::Product::Master.where(id: ids).each do |master|
                master.variants.each do |v|
                  v.variant_vouchers.find_or_create_by(voucher_id: @product_voucher.id)
                end
              end
            end
          end
          redirect_to product_masters_path
        end

        def merge_update
          ids = params[:ids].split(' ').map(&:to_i)
          master = C::Product::Master.find(params[:master])
          ids.delete(master.id)

          C::Product::Master.where(id: ids).each do |old_master|
            master.merge_with(old_master)
          end

          redirect_to [:edit, master]
        end

        def new_duplicate
          @product = @master.deep_clone(include: [:main_variant])
        end

        def create_duplicate
          @product = @master.deep_clone(
            include: %i[
              amazon_channel
              ebay_channel
              web_channel
              categorizations
              main_variant
            ],
            except: [
              main_variant: [
                :slug,
                {
                  web_price: :without_tax_pennies,
                  ebay_price: :without_tax_pennies,
                  amazon_price: :without_tax_pennies,
                  retail_price: :without_tax_pennies
                }
              ]
            ]
          )
          if @product.web_price
            @product.web_price = @product.web_price.deep_clone(
              except: :without_tax_pennies
            )
          end
          if @product.retail_price
            @product.retail_price = @product.retail_price.deep_clone(
              except: :without_tax_pennies
            )
          end
          if @product.ebay_price
            @product.ebay_price = @product.ebay_price.deep_clone(
              except: :without_tax_pennies
            )
          end
          if @product.amazon_price
            @product.amazon_price = @product.amazon_price.deep_clone(
              except: :without_tax_pennies
            )
          end
          main_variant_attributes = params[:product_master][:main_variant_attributes]
          @product.assign_attributes(
            main_variant_attributes: { sku: main_variant_attributes[:sku],
                                       name: main_variant_attributes[:name],
                                       item_id: nil,
                                       ebay_last_push_success: nil,
                                       ebay_last_push_body: nil,
                                       ebay_product_pipeline_id: nil,
                                       amazon_product_pipeline_id: nil,
                                      },
            amazon_channel_attributes: { name: main_variant_attributes[:name] },
            ebay_channel_attributes: { name: main_variant_attributes[:name] },
            web_channel_attributes: { name: main_variant_attributes[:name] }
          )

          if @product.save

            @product.variants.each do |var|
              var.update!(slug: var.send(C.duplication_slug_attr).parameterize)
            end

            @master.images.each_with_index do |image, i|
              begin
                new_image = @product.images.create!(remote_image_url:
                                                        image.image.url)

                new_channel_image = @product.web_channel
                                            .channel_images
                                            .create!(image: new_image)
                new_channel_image._weight.update(value: i)

                new_channel_image = @product.ebay_channel
                                            .channel_images
                                            .create!(image: new_image)
                new_channel_image._weight.update(value: i)

                new_channel_image = @product.amazon_channel
                                            .channel_images
                                            .create!(image: new_image)
                new_channel_image._weight.update(value: i)
              rescue
                'No valid image at remote url'
              end
            end

            @master.ebay_channel.ship_to_locations.each do |ship_to|
              @product.ebay_channel.ship_to_locations
                      .create!(location: ship_to.location)
            end

            @master.ebay_channel.shipping_services.each do |service|
              @product.ebay_channel.shipping_services.create!(
                delivery_service_id: service.delivery_service_id,
                international: service.international,
                cost_pennies: service.cost_pennies,
                cost_currency: service.cost_currency,
                additional_cost_pennies: service.additional_cost_pennies,
              )
            end

            redirect_to edit_product_master_path(@product)
          else
            render :new_duplicate
          end
        end

        def remote_show
          @master.web_price || @master.main_variant.build_web_price
          @master.ebay_price || @master.main_variant.build_ebay_price
          @master.amazon_price || @master.main_variant.build_amazon_price

          if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
            @amazon_pipeline_message = @master.main_variant.amazon_product_pipeline_data["message"]
            @amazon_pipeline_error = @master.main_variant.amazon_product_pipeline_data["error"]
            @amazon_pipeline_logs = C::AmazonPipeline.logs(
              @master.variants.where.not(amazon_product_pipeline_id: nil)
            )
          else
            job = C::AmazonJob.new
            @amazon_validation_errors = job.validate_product(
              job.create_product_listing(@master.main_variant)
            )
            @amazon_return_errors = @master.amazon_processing_queues
              .product
              &.last
              &.failure_messages_for(@master)
          end

          render layout: false
        end

        def create_from_ebay
          return unless params[:ItemID]
          if ENV['USE_EBAY_PRODUCT_PIPELINE']
            local_listing = C::Product::Variant.find_by(item_id: params[:ItemID])
            if !local_listing
              master = C::Product::Master.create!(
                main_variant_attributes: { 
                  sku: params[:ItemID], 
                  item_id: params[:ItemID],
                  build_from_ebay: true
                }
              )
              local_listing = master.main_variant
              C::EbayPipeline.new(local_listing).build
            end
            flash[:success] = 'Husk product created, will sync from eBay imminently'
            redirect_to edit_product_master_path(local_listing.master)
          else
            local_listing = C::EbayJob.perform_now('create_single_local_item', obj: params[:ItemID])
            if local_listing.class == String
              flash[:error] = local_listing
              render :create_from_ebay
            else
              flash[:success] = 'Valid ItemID'
              redirect_to edit_product_master_path(local_listing.master)
            end
          end
        end

        # For eBay wrap preview on the channel tabs
        # Would use raw html in the view but they have embedded styles which
        # override commercity styles
        def render_ebay_wrap
          render html: @master.ebay_channel.subbed_shop_wrap(@master.main_variant.channel_description_fallback('ebay'), @master.main_variant.price(channel: :ebay, fallback: :web))&.html_safe
        end

        def price_match
          @products = C::Product::Variant.joins(:price_matches).group('c_product_variants.id')
        end

        def save_price_match
          price_match = C::Product::PriceMatch.find_by(id: params[:price_match_id])
          main_variant = @master.main_variant

          if price_match.price_pennies < main_variant.retail_price.with_tax_pennies
            main_variant.retail_price.update(with_tax_pennies: price_match.price_pennies)
            flash[:success] = "Retail price updated"
            redirect_to edit_product_master_path
          end
        end

        def save_best_price_match
          main_variant = @master.main_variant
          best_price_pennies = main_variant.price_matches.minimum(:price_pennies)
          if best_price_pennies && best_price_pennies > 0 && best_price_pennies < main_variant.retail_price.with_tax_pennies
            main_variant.retail_price.update(with_tax_pennies: best_price_pennies)
            flash[:success] = "Retail price updated"
            redirect_to price_match_product_masters_path
          end
        end

        def update_price_matches
          main_variant = @master.main_variant
          compare_prices = C::ComparePrices.new
          main_variant.price_matches.update_all(updated_at: Time.current - 2.days)
          compare_prices.perform(main_variant.id)
          flash[:success] = "Price matches updated"
          redirect_to price_match_product_masters_path
        end

        def toggle_amazon_published
          variant = C::Product::Variant.find_by(id: params['obj_id'])
          return unless variant
          variant.toggle!(:published_amazon)
        end

        def toggle_ebay_feature_image
          if (feature = @master.ebay_channel.feature_images.find_by(image_id: params['obj_id']))
            feature.destroy
          else
            @master.ebay_channel.feature_images.create(image_id: params['obj_id'])
          end
        end

        def toggle_ebay_feature_block
          if (feature = @master.main_variant.product_features.find_by(feature_id: params['obj_id']))
            feature.destroy
          else
            @master.main_variant.product_features.create(feature_id: params['obj_id'])
          end
        end

        def sort_product_features
          C::Product::Master.find(params[:id]).main_variant.product_features.update_order(params[:feature])
          respond_to do |format|
            format.js { head :ok, content_type: 'text/html' }
          end
        end

        def sort_feature_images
          C::Product::Master.find(params[:id]).ebay_channel.feature_images.update_order(params[:image])
          respond_to do |format|
            format.js { head :ok, content_type: 'text/html' }
          end
        end

        def reload_toggle
          respond_to do |format|
            format.js do
              @target = params[:target]
            end
          end
        end

        def clear_ebay_item_id
          return unless C.clear_ebay_item_id
          @master.variants.each { |v| v.update(item_id: nil)}
          redirect_to edit_product_master_path
        end

        private

        # this junky code sets weights to each of the webchannel images
        def weights
          channel_images = [@master.amazon_channel.channel_images,
                            @master.ebay_channel.channel_images,
                            @master.web_channel.channel_images]
          if !params['web_weights'].nil? &&
             !channel_images[2].nil? &&
             !channel_images[2].empty?
            params['web_weights'].each do |k, v|
              channel_images[2].find_by(id: k.to_i).update(weight: v.to_i)
            end
          end
          if !params['amazon_weights'].nil? &&
             !channel_images[0].nil? &&
             !channel_images[0].empty?
            params['amazon_weights'].each do |k, v|
              channel_images[0].find_by(id: k.to_i).update(weight: v.to_i)
            end
          end
          return if params['ebay_weights'].nil? ||
                    channel_images[1].nil? ||
                    channel_images[1].empty?
          params['ebay_weights'].each do |k, v|
            channel_images[1].find_by(id: k.to_i).update(weight: v.to_i)
          end
        end

        def duplicate_params
          params.require(:product_master).permit(:sku)
        end

        def master_params
          params.require(:product_master).permit(
            :brand_id,
            :condition,
            :manufacturer_id,
            :tax_rate,
            related_product_ids: [],
            add_on_ids: [],
            category_ids: [],
            main_variant_attributes: [:id, :name, :sku, :cost_price, :rrp, :ebay_sku, :image_variant_id, :no_barcodes, :three_sixty_image, :click_and_collect,
                                      :sticky, :mpn, :package_quantity, :current_stock, :asin, :published_amazon,
                                      :published_ebay, :published_web, :includes_tax, :oe_number, :order,
                                      :country_of_manufacture_id, :product_tag, :delivery_override, :weight, :created_at, :display_only,
                                      :manufacturer_product_url, :has_delivery_override, :x_dimension, :y_dimension, :z_dimension, :dimension_unit,
                                      :slug, :title, :meta_description, :bundle, service_ids: [], option_ids: [], feature_ids: [],
                                                                                 info: C.product_info_fields.keys,
                                                                                 bundle_items_attributes: %i[id _destroy variant_id bundled_variant_id web_price ebay_price amazon_price quantity],
                                                                                 property_values_attributes: %i[id
                                                                                                                _destroy
                                                                                                                property_key_id
                                                                                                                value
                                                                                                                variant_id
                                                                                                                manufacturer_product_url],
                                                                                 page_info_attributes: %i[id title meta_description],
                                                                                 retail_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                 web_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                 amazon_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                 ebay_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                 barcodes_attributes: %i[id _destroy value symbology variant_id],
                                                                                 price_matches_attributes: %i[id _destroy competitor url price variant_id],
                                                                                 variant_dimensions_attributes: %i[id _destroy weight x_dimension y_dimension z_dimension dimension_unit notes]],
            variants_attributes: [:id, :name, :sku, :barcode_value, :manufacturer_product_url, :oe_number, :ebay_sku, :image_variant_id, :no_barcodes, :order,
                                  :featured, :published_amazon, :published_ebay, :display_in_lists, :current_stock, :status,
                                  :package_quantity, :current_stock, :bundle, :active, :includes_tax, :weight, option_ids: [],
                                                                                                               retail_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                                               web_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                                               amazon_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                                               ebay_price_attributes: %i[id without_tax with_tax tax_rate override],
                                                                                                               barcodes_attributes: %i[id _destroy value symbology variant_id],
                                                                                                               price_matches_attributes: %i[id _destroy competitor url price variant_id]],
            new_images: [],
            images_attributes: %i[id _destroy alt image image_cache main_image],
            new_documents: [],
            documents_attributes: %i[id name document _destroy],
            amazon_channel_attributes: [:id, :name, :recommended_browse_nodes, :description,
                                        :key_product_features, :condition_note, :current_price, :de_price, :es_price,
                                        :fr_price, :it_price, :shipping_cost, :product_type_id, :amazon_category_id,
                                        :ebc_logo, :ebc_description, :ebc_module1_heading, :ebc_module1_body,
                                        :ebc_module2_heading, :ebc_module2_sub_heading, :ebc_module2_body, :ebc_module2_image,
                                        amazon_search_terms_attributes: %i[id _destroy term],
                                        bullet_points_attributes: %i[id _destroy value],
                                        amazon_browse_node_ids: []],
            web_channel_attributes: %i[name sub_title description features specification current_price discount_price id],
            ebay_channel_attributes: [:id, :name, :sub_title, :ebay_category_id, :body, :description, :features,
                                      :start_price, :duration, :country, :condition, :postcode, :condition_description, :payment_method_paypal, :payment_method_postal,
                                      :payment_method_cheque, :payment_method_other, :payment_method_cc, :global_shipping, :payment_method_money_order,
                                      :payment_method_escrow, :delivery_service_id, :domestic_shipping_type, :domestic_shipping_service_cost,
                                      :domestic_shipping_service_additional_cost, :dispatch_time, :pickup_in_store, :x_dimension, :y_dimension, :z_dimension, :dimension_unit,
                                      :click_collect_collection_available, :international_shipping_service, :international_shipping_service_id,
                                      :international_shipping_service_cost, :international_shipping_service_additional_cost, :no_shipping_options,
                                      :returns_accepted, :restocking_fee_value_option, :returns_description, :refund_option, :shop_wrap, :max_stock, :uses_ebay_catalogue, :package_type,
                                      :returns_within, :returns_cost_paid_by, :warranty_offered, :warranty_duration, :warranty_type, :wrap_text_1, :wrap_text_2, :classifier_property_key_id,
                                      ship_to_locations_attributes: %i[id _destroy ebay_id location],
                                      wrap_image_ids: [],
                                      shipping_services_attributes: %i[id _destroy ebay_id delivery_service_id international cost additional_cost]],
            channel_image_attributes: %i[id web_channel_id amazon_channel_id
                                         ebay_channel_id image_id],
            weight_attributes: [:value]

          )
        end
      end
    end
  end
end

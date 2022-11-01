# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      class VariantsController < AdminController
        before_filter only: :edit do
          redirect_slug
        end
        load_and_authorize_resource :master,
                                    class: C::Product::Master, except: :show
        load_and_authorize_resource class: C::Product::Variant,
                                    through: :master, except: :show
        load_and_authorize_resource class: C::Product::Variant, only: :show

        def index
          @variants = @master.variants
        end

        def show
          respond_to do |format|
            format.json do
              render json: { variant: @variant }
                .merge(master: @variant.master)
            end
          end
        end

        def new
          @variant = @master.variants.build
        end

        def create
          original_id = params["product_variant"]["duplicate_id"]

          property_values_attributes = variant_params["property_values_attributes"]
          create_variant_params = variant_params.except("property_values_attributes", "duplicate_id")

          @variant = @master.variants.build(create_variant_params)
          @original_variant = nil

          if original_id.present?
            @original_variant = C::Product::Variant.find(original_id)
          end

          if @variant.save  
            if property_values_attributes.present?
              @variant.update(property_values_attributes: property_values_attributes)
            end

            case params[:commit]
              
            when 'Auto assign new Barcode'
              barcode = C::Product::Barcode.unassigned.first
              @variant.barcodes.append(barcode) if barcode.present?
            end

            flash[:success] = 'Variant created!'
            redirect_to edit_product_master_path(@master)
          else
            flash.now[:danger] = 'Variant not created!'

            @variant.assign_attributes(variant_params)

            if @original_variant.present?
              render :new_duplicate
            else
              render :new
            end
          end
        end

        def edit
          @variant.build_nested_elements
        end

        def update
          options_ids_next = variant_params["option_ids"].select(&:presence).map(&:to_i)

          options_are_bad = @variant.options_are_changing_but_they_on_a_cart(options_ids_next)

          if options_are_bad
            variant_params_hash = variant_params.to_h
            variant_params_hash["option_ids"] = @variant.option_ids
            @variant.assign_attributes(variant_params_hash)

            flash[:error] = "Can't update product - currently assigned options are in a cart"
            return render :edit
          end


          if @variant.update(variant_params)

            case params[:commit]
              
            when 'Auto assign new Barcode'
              barcode = C::Product::Barcode.unassigned.first
              @variant.barcodes.append(barcode) if barcode.present?
            end

            if @variant.inactive? || !@variant.published_ebay
              C::EbayJob.perform_later('make_listings_inactive',
                                       obj: @variant.master)
            elsif C::Setting.get(:ebay_sync)
              if ENV['USE_EBAY_PRODUCT_PIPELINE']
                if (@variant.master.main_variant.item_id.present? && @variant.master.main_variant.ebay_product_pipeline_id.present?)
                  C::EbayPipeline.new(@variant.master.main_variant).push
                end
              else
                @variant.master.ebay_channel.auto_push
              end
            end

            flash[:success] = 'Variant Updated!'
            redirect_to edit_product_master_path(@master)
          else
            render :edit
          end
        end

        def destroy
          @variant.destroy!
          redirect_to edit_product_master_path(@master), notice: 'Variant Deleted'
        end

        def assign_image
          @master = C::Product::Master.find(params[:master_id])
          @image = @master.images.find(params[:image_id])
          @variant = C::Product::Variant.find(params[:id])
          @variant.images.append(@image)
          respond_to do |format|
            format.html { redirect_to edit_product_master_product_variant_path(@master, @variant) }
            format.js do
              @channel_type = params[:channel_type]
            end
          end
        end

        def unassign_image
          @master = C::Product::Master.find(params[:master_id])
          @variant = C::Product::Variant.find(params[:id])
          @image = @variant.images.find(params[:image_id])
          @variant.images.delete(@image)
          respond_to do |format|
            format.html { redirect_to edit_product_master_product_variant_path(@master, @variant) }
            format.js do
              @channel_type = params[:channel_type]
            end
          end
        end

        def new_duplicate
          cloned_variant = @variant.deep_clone(
            include: %i[
              property_values
              options
            ],
            except: [
              :main_variant,
              :slug,
              :item_id,
              :ebay_last_push_success,
              :ebay_last_push_body,
              :ebay_product_pipeline_id,
              :amazon_product_pipeline_id,
            ]
          )

          @original_variant = @variant
          @variant = cloned_variant

          @variant.sku = "#{@variant.sku}-DUPE"

          @variant.build_ebay_price(with_tax: @original_variant.ebay_price&.with_tax)
          @variant.build_web_price(with_tax: @original_variant.web_price&.with_tax)
          @variant.build_amazon_price(with_tax: @original_variant.amazon_price&.with_tax)
          @variant.build_retail_price(with_tax: @original_variant.retail_price&.with_tax)

          if @original_variant.main_variant?
            if ActionController::Base.helpers.strip_tags(@original_variant.web_channel.description).present?
              @variant.description = @original_variant.web_channel.description
            end
          else
            if ActionController::Base.helpers.strip_tags(@original_variant.description).blank?
              @variant.description = @original_variant.web_channel.description
            end
          end
        end

        private

        def redirect_slug
          @variant = C::Product::Variant.find_by(id: params[:id])
          return if @variant
          return unless params[:id].gsub(/\d/, '').present?
          @variant = C::Product::Variant.find_by(slug: params[:id])
          redirect_to [:edit, @variant.master, @variant]
        end

        def variant_params
          params.require(:product_variant).permit(
            :name, :sku, :mpn, :asin, :current_stock, :discontinued, :published, :no_barcodes,
            :barcode_value, :barcode_type, :x_dimension, :y_dimension, :z_dimension, :dimension_unit,
            :cost_price, :retail_price, :rrp, :shop_price, :order,
            :ebay_price, :amazon_price, :description, :featured,
            :delivery_override, :status, :includes_tax, :display_in_lists,
            :publishable_web, :publishable_ebay, :publishable_amazon, :active,
            :url_alias, :published_ebay,
            :oe_number, :package_quantity, :weight, :country_of_manufacture_id, :manufacturer_product_url,
            :has_delivery_override, :published_web, :published_amazon,
            :slug, :title, :meta_description, :image_variant_id,
            info: C.product_info_fields.keys,
            property_values_attributes: %i[id
                                           _destroy
                                           value property_key_id],
            page_info_attributes: %i[id title meta_description],
            barcodes_attributes: %i[id value symbology _destroy],
            associate_image: [],
            option_ids: [],
            web_price_attributes: %i[
              id without_tax with_tax tax_rate override
            ],
            amazon_price_attributes: %i[
              id without_tax with_tax tax_rate override
            ],
            ebay_price_attributes: %i[
              id without_tax with_tax tax_rate override
            ],
            retail_price_attributes: %i[
              id without_tax with_tax tax_rate override
            ]
          )
        end
      end
    end
  end
end

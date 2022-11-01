# frozen_string_literal: true

# Front end product display

# Gets the product from its slug
# Assigns the attributes for meta elements
# Creates an array of the recent products visitor has visited

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class ProductsController < MainApplicationController

      def index
        respond_to do |format|
          format.xml do
            render 'c/front_end/products/index.xml.haml'
          end
          format.csv do
            cwave_host = Rails.env == "development" ? "/uploads/c/product/image/image/" : "https://#{ENV['S3_BUCKET']}.s3.amazonaws.com/uploads/c/product/image/image/"

            q = <<-SQL.squish
              SELECT
                variant.id,
                variant.sku,
                variant.name,
                FIRST(web_channel.description),
                FIRST(round(retail_price.with_tax_pennies::decimal / 100, 2)),
                STRING_AGG(DISTINCT '#{cwave_host}' || images.id || '/' || images.image, ', '),
                FIRST(brand.name),
                variant.status,
                variant.published_web,
                variant.current_stock,
                variant.slug
              FROM c_product_variants AS variant
              LEFT JOIN c_product_masters AS master ON master.id = variant.master_id
              LEFT JOIN c_product_variants AS masters_variants ON masters_variants.master_id = master.id
              LEFT JOIN c_product_channel_webs AS web_channel ON web_channel.master_id = master.id
              LEFT JOIN c_prices AS retail_price ON retail_price.id = variant.retail_price_id
              LEFT JOIN c_brands AS brand ON brand.id = master.brand_id
              LEFT JOIN c_product_images AS images ON images.master_id = master.id
              WHERE master.id IN (?)
              GROUP BY variant.id
            SQL

            connection = ActiveRecord::Base.connection()
            result = connection.execute(ActiveRecord::Base.send(:sanitize_sql, [q, C::Product::Master.order(created_at: :desc).pluck(:id)]))

            rows = result.values

            csv_string = CSV.generate do |csv|
              csv << %w(id title description availability condition price link image_link brand inventory fb_product_category)
              rows.each do |row| 
                # https://developers.facebook.com/docs/commerce-platform/catalog/fields#supported-feed-formats
                # [1, "5461068109718", "Farm To Table Kombucha", "", "75.84", nil, "Jacobs, Simonis and Gleason", 1, false, -1]

                # in stock - Item ships immediately.
                # available for order - Ships in 1-2 weeks.
                # out of stock - Not available in current stock.
                # discontinued - Discontinued.

                # 173	auto parts & accessories > car parts & accessories

                id = row[0]
                sku = row[1]
                title = row[2]
                desc = ActionController::Base.helpers.strip_tags(row[3])
                price = row[4]
                images = row[5]
                brand = row[6]
                status = row[7]
                published_web = row[8]
                current_stock = row[9]
                slug = row[10]

                availability = "in stock"

                if 0 >= current_stock
                  availability = "out of stock"
                end

                if status != 0 || !published_web
                  availability = "discontinued"
                end

                image_link = ""

                if images.present?
                  links = images.split(", ")
                  image_link = links[0]
                end

                formatted = [
                  sku,
                  title,
                  desc,
                  availability,
                  'used',
                  "#{price} GBP",
                  "https://#{C.domain_name}/products/#{slug}",
                  image_link,
                  brand,
                  current_stock,
                  173,
                ]
                csv << formatted
              end
            end
            render :csv => csv_string, :filename => "upload" 
          end
        end
      end

      def show
        @product = C::Product::Variant.from_url(params[:id])
        redirect_to '/' if @product.inactive? || !@product.published_web
        assign_page_info @product.page_info
        session[:recent_products] = (
          (session[:recent_products] || []) - [@product.id])
                                    .unshift(@product.id).first(4)
        @tree = @product.property_tree
      end

      def search
        search_term = params[:f_search]
        if C::Product::Variant.for_display.where(sku: search_term).count == 1
          redirect_to front_end_product_path(
            C::Product::Variant.find_by(sku: search_term).slug
          )
        end

        @q = C.show_all_in_search ? C::Product::Variant.sellable : C::Product::Variant.for_display
        @q = @q.includes(:master).text_search(search_term).ransack(params[:q])

        if @q.sorts.empty?
          if C.default_category_products_sort.present?
            @q.sorts = Array.wrap(C.default_category_products_sort)
          else
            @q.sorts = Array.wrap(C.default_products_sort)
          end
        end

        @products = @q.result
        @products = @products.in_stock if C.hide_zero_stock_products

        @products = @products.paginate(page: params[:page],
                                       per_page: (params[:per_page] || C.products_per_category_page))
      end
    end
  end
end

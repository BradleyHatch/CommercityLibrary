# frozen_string_literal: true

module C
  module StorefrontHelper
    # On the right hand of the admin bar
    # Use a case statement to grab appropriate edit section
    def admin_edit_path
      if action_name == 'show'
        case controller_name
        when 'products'
          edit_product_master_path(@product.master.id)
        when 'brands'
          edit_brand_path(@brand.id)
        when 'categories'
          edit_category_path(@category.id)
        when 'contents'
          edit_content_path(@content.id)
        else
          false
        end
      end
    end

    def slideshow(slideshow_name, _klass=nil)
      slide_show = C::Slideshow.find_by(machine_name: slideshow_name)
      return 'No slideshow found' unless slide_show
      content_tag :div, class: :slideshow do
        content_tag :ul do
          safe_join(slides(slide_show))
        end
      end
    end

    def slides(slide_show)
      slide_show.slides.map do |slide|
        content_tag(:li) do
          if slide.url.blank?
            image_tag(slide.image)
          else
            link_to image_tag(slide.image), slide.url
          end
        end
      end
    end

    def sales_highlights(limit=4)
      safe_join(C::SalesHighlight.first(limit).map do |sales_highlight|
        link_to(image_tag(sales_highlight.image.url.to_s),
                ((sales_highlight.url.blank? ? 'javascript:void(0)' : sales_highlight.url)).to_s,
                class: ('nolink' if sales_highlight.url.blank?),
                style: "background-color:#{sales_highlight.color}",
                target: '_blank')
      end)
    end

    def brand_filter_links
      brands = @category.self_and_descendant_brands
      brand_links = brands.map do |brand|
        link_to brand.name.to_s, front_end_category_path(brand_filter: brand.id)
      end
      safe_join brand_links
    end

    def site_search(search_object=@q, search_text='Search', &block)
      return if search_object.blank?
      form_tag search_front_end_products_path, method: :get, class: 'site_search site-search__form' do
        text_field_tag(:f_search, params[:f_search], placeholder: 'Search') + \
          button_tag(search_text, &block)
      end
    end

    def variant_switcher(product)
      variants = product.variants.order(:cache_web_price_pennies).map do |variant|
        vals = " - #{variant.property_values.map { |v| v.value }.join(', ')}" if variant.property_values.any?
        ["#{variant.name} (#{humanized_money_with_symbol(variant.cache_web_price)})#{vals if vals.present?}", variant.slug]
      end.compact

      return unless variants.count > 1
      content_tag(:div, id: 'product_switcher') do
        select_tag(:product_switcher_select,
                   options_for_select(variants, product.slug))
      end
    end

    def product_images(product, thumbnails_locations=nil, nopad=nil, limit=nil)
      content_tag :div, class: 'product-show__images' do
        arr = [product_images_main(product, nopad), product_images_thumbnails(product, limit)]
        if thumbnails_locations == :left
          arr = [content_tag(:div, arr[1], class: 'g-1'), content_tag(:div, arr[0], class: 'g-4')]
          content_tag :div, safe_join(arr), class: 'gs'
        else
          safe_join arr
        end
      end
    end

    def get_alt_tag_for_an_image(image, product)
      if image.is_a? String
        return product.name
      end
      image&.model&.alt.present? ? image.model.alt : product.name
    end

    def product_images_main(product, nopad=nil)
      image = nopad ? product.primary_web_image(:product_standard_no_pad) : product.primary_web_image
      content_tag(:div,
                  class: 'product-show__main_image',
                  data: { 'original': product.primary_image&.url }) do
        image_tag(image,
                  alt: get_alt_tag_for_an_image(image, product),
                  class: (:placeholder_img unless product.web_channel_images.any?),
                    data: { 'zoom-image': product.primary_image&.url })
      end
    end

    def product_images_thumbnails(product, limit)
      content_tag(:div, class: 'product-show__thumbnails') do
        collection = product.image_collection(:web)
        collection = collection[0...limit] if limit
        images = collection.map do |image|
          image_tag(image.thumbnail, alt: get_alt_tag_for_an_image(image, product), class: 'product-show__thumbnail')
        end
        safe_join(images)
      end
    end

    def get_product_ids_from_params(keys)
      keys = params.keys.map(&:to_sym) & keys
      vals = keys.map { |k| params[k] }
      C::Product::Variant
        .joins(property_values: [:property_key])
        .group(:id)
        .where(c_product_property_values: { value: vals })
        .having('COUNT(c_product_property_values.id) = ?', vals.length)
        .pluck(:id)
        .uniq
    end

    def filter_list(prod_ids, property_key, param)
      content_tag :ul do
        if params[param]
          content_tag :li, class: 'active' do
            link_to "- #{params[param]}", url_for(params.except(:page).permit!.except(param))
          end
        else
          keys = if prod_ids.empty?
                   property_key.property_values.pluck(:value).uniq.sort.map do |v|
                     content_tag :li do
                      link_to(v, url_for(params.except(:page).permit!.merge(param.to_sym => v)))
                     end
                   end
                 else
                   property_key.property_values.where(variant_id: prod_ids).pluck(:value).uniq.sort.map do |v|
                     content_tag :li do
                      link_to(v, url_for(params.except(:page).permit!.merge(param.to_sym => v)))
                     end
                   end
          end
          safe_join keys
        end
      end
    end

    def template_regions(group, breakpoint=nil)
      return nil if group.blank? || group.regions.empty?
      content_tag :div, class: 'home-blocks' do
        safe_join group.regions.ordered.map { |r| template_blocks(r, breakpoint) }
      end
    end

    def template_blocks(region, breakpoint=nil)
      content_tag :div, class: "gs#{breakpoint}" do
        safe_join region.blocks.ordered.map { |b| template_block(b) }
      end
    end

    def template_block(block)
      if block.url.blank?
        send_type = 'content_tag'
        send_option = :div
      else
        send_type = 'link_to'
        send_option = block.url
      end

      send(send_type,
          send_option,
          class: "home-block home-block--#{block.kind_of} #{block.get_html_class} #{'home-block--slider' if block.kind_of == 'slideshow'}",
          style: ("background-image: url('#{block.get_image&.url}')" if block.kind_of == 'image')
          ) do
            if block.kind_of == 'slideshow'
              content_tag :div, class: :slides do
                safe_join(template_slides(block))
              end
            elsif block.kind_of == 'text'
              raw block.body
            end
          end
    end

    def template_slides(block)
      block.images.map do |image|
        content_tag :li, class: "home-block home-block--image #{block.get_html_class}", style: "background-image: url('#{image.image.url}')" do
        end
      end
    end

  end
end

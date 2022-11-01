# frozen_string_literal: true

xml.instruct!
xml.urlset(
  'xmlns'.to_sym => 'http://www.sitemaps.org/schemas/sitemap/0.9',
  'xmlns:image'.to_sym => 'http://www.google.com/schemas/sitemap-image/1.1'
) do
  @content.each do |page|
    xml.url do
      if page[:root]
        xml.loc front_end_root_url
      elsif page.basic_page?
        xml.loc front_end_content_url(page)
      else
        xml.loc front_end_content_typed_url(page.content_type, page)
      end
      xml.changefreq('weekly')
    end
  end
  if @products.any?
    @products.each do |product|
      xml.url do
        xml.loc front_end_product_path(id: product.id)
        xml.changefreq('weekly')
      end
    end
  end
end

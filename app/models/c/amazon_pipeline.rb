require 'httparty'

class C::AmazonPipeline
  class << self
    def push variants
      Array.wrap(variants).each { |variant| new(variant).push }
      true
    end

    def status variants
      Array.wrap(variants).each { |variant| new(variant).status }
      true
    end

    def save_data variants, data
      Array.wrap(variants).each { |variant| new(variant).save_data data }
      true
    end

    def logs variants
      logs = Array.wrap(variants).map { |variant| new(variant).logs }
      logs.flatten.sort_by { |log| 0 - Time.parse(log["createdAt"]).to_i }
    rescue => e
      [
        {
          "type" => "error",
          "logData" => e.as_json,
          "source" => "",
          "message" => e.message,
          "createdAt" => Time.current.as_json,
        }
      ]
    end

    def destroy variants
      Array.wrap(variants).each { |variant| new(variant).destroy }
      true
    end

    def push_changed
      variants = C::Product::Variant.where(should_push_to_amazon_pipeline: true).where('published_amazon OR amazon_product_pipeline_id IS NOT NULL')
      variants.each do |variant|
        puts "-- pushing to pipline #{variant.sku}"
        new(variant).push rescue nil
      end
      variants.update_all(should_push_to_amazon_pipeline: false)
      true
    end

    def push_all
      C::Product::Variant.where('published_amazon OR amazon_product_pipeline_id IS NOT NULL').each do |variant|
        puts "-- pushing to pipline #{variant.sku}"
        new(variant).push rescue nil
      end
      true
    end

    def status_all
      C::Product::Variant.where('amazon_product_pipeline_id IS NOT NULL').each do |variant|
        puts "-- getting status from pipline #{variant.sku}"
        new(variant).status rescue nil
      end
      true
    end
  end

  attr_reader :variant

  def initialize(variant)
    @variant = variant
  end

  def push
    return unless C::Setting.get(:amazon_sync)
    if (variant.amazon_product_pipeline_id)
      if variant.published_amazon
        request("/api/amazon/products/#{variant.amazon_product_pipeline_id}/update", serialize)
        list
      else
        unlist
      end
    else
      if variant.published_amazon
        record = request('/api/amazon/products/create', serialize)
        variant.update_columns(amazon_product_pipeline_id: record[:id])
        list
      end
    end

    save_data(error: nil)
    variant.master.amazon_channel.update!(last_push_success: true)
  rescue => e
    save_data(error: e.message)
    variant.master.amazon_channel.update!(last_push_success: false)
    raise e
  end

  def destroy
    request("/api/amazon/products/#{variant.amazon_product_pipeline_id}/destroy")
    variant.update_columns(amazon_product_pipeline_id: nil)
  end

  def list
    request("/api/amazon/products/#{variant.amazon_product_pipeline_id}/list")
    true
  rescue => e
    raise e unless e.message.match?(/already listed/)
    false
  end

  def unlist
    request("/api/amazon/products/#{variant.amazon_product_pipeline_id}/unlist")
    true
  rescue => e
    raise e unless e.message.match?(/already unlisted/)
    false
  end

  def status
    response = request("/api/amazon/products/#{variant.amazon_product_pipeline_id}/status")
    data = { status: response["status"] }

    important = -> (status) { status.in? ["complete", "failed"] }
    old_status = variant.amazon_product_pipeline_data["status"]
    new_status = response["status"]

    # Avoid periodic updates overwriting the failure/success messages
    unless important[old_status] && !important[new_status]
      data["message"] = response["syncMessage"]
    end

    variant.amazon_channel.update(last_push_success: true) if new_status == "complete"
    variant.amazon_channel.update(last_push_success: false) if new_status == "failed"
    
    save_data(data)
  end

  def logs
    request("/api/amazon/products/#{variant.amazon_product_pipeline_id}/logs")
  end

  def serialize
    variant.validate!
    master = variant.master
    master.validate!
    barcode = variant.barcode
    channel = master.amazon_channel
    product_type = channel.product_type ||
      master.categories.where.not(amazon_product_type_id: nil).first!.amazon_product_type
    price = variant.price(channel: :amazon, fallback: :web)

    return clean({
      sku: variant.sku,
      name: channel.name,
      condition: "New",
      "barcode#{barcode&.symbology&.titleize}": barcode&.value,
      brand: master.brand.name,
      description: sanitize(channel.description.presence || master.web_channel.description || ""),
      manufacturer: master.manufacturer&.name,
      bulletPoints: channel.bullet_points.limit(5).pluck(:value),
      mpn: master.main_variant.mpn,
      images: channel.channel_images.ordered.limit(9).map.with_index do |image, i|
        { url: image.image.image.url.gsub(/\Ahttps/i, 'http'), type: i === 0 ? "Main" : "PT#{i}" }
      end,
      searchTerms: channel.amazon_search_terms.pluck(:term),
      quantity: variant.current_stock,
      price: price.to_f,
      currency: price.currency.iso_code,
      recommendedBrowseNodes: channel.amazon_browse_nodes.pluck(:node_id),
      # colorSpecification: variant.property('Color')&.value,
      # countryProducedIn: variant.country_of_manufacture&.name,
      department: lower_camel(product_type.amazon_category.name),
      departmentData: {
        productType: lower_camel(product_type.name),
        productData: {}
      },
      ebc: channel.ebc_valid? ? {
        companyLogoUrl: channel.ebc_logo.url,
        productDescriptionText: channel.ebc_description,
        module1: {
          heading: channel.ebc_module1_heading,
          body: channel.ebc_module1_body,
        },
        module2: {
          heading: channel.ebc_module2_heading,
          subHeading: channel.ebc_module2_sub_heading,
          body: channel.ebc_module2_body,
          imageUrl: channel.ebc_module2_image.url,
        },
      } : nil,
    })
  end

  def lower_camel string
    string[0].downcase + string.camelcase[1..-1]
  end

  def sanitize string
    string = string.gsub(/<(\/?)strong>/, '<\1b>')
    string = string.gsub(/<(\/?)em>/, '<\1i>')
    string = string.gsub(/<span style="text-decoration: underline;">(.*?)<\/span>/, '<u>\1</u>')
    ActionController::Base.helpers.sanitize(string, tags: %w[b i u p br])
  end

  def clean(data)
    if data.is_a?(Hash)
      return data.map { |k, v| [k, clean(v)] }.to_h.compact
    elsif data.is_a?(Array)
      return data.map { |x| clean(x) }.compact
    else
      return data
    end
  end

  def indifferent(data)
    if data.is_a?(Hash)
      return data.with_indifferent_access
    elsif data.is_a?(Array)
      return data.map { |x| indifferent(x) }
    else
      return data
    end
  end

  def request(path, body = {})
    start = Time.current
    url = "#{ENV['PIPELINE_URL']}#{path}"
    response = HTTParty.post(
      url,
      body: body.to_json,
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    )

    response = response.parsed_response

    return indifferent(response["data"]) if (response["data"])
    raise String(response.dig('error', 'message') || response["error"] || response)
  end

  def save_data data
    new_data = variant.amazon_product_pipeline_data.merge(data.stringify_keys)
    variant.update_columns(amazon_product_pipeline_data: new_data)
  end
end

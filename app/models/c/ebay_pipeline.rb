class C::EbayPipeline

  #####################
  # class methods
  #####################

  def self.status_all
    C::Product::Variant.where('ebay_product_pipeline_id IS NOT NULL').each do |variant|
      puts "-- getting status from pipline #{variant.sku}"
      new(variant).status rescue nil
    end
    true
  end

  #####################
  #####################
  #####################

  attr_reader :variant
  attr_reader :master
  attr_reader :ebay_channel
  attr_reader :web_channel

  def initialize(variant)
    @variant = variant
    @master = variant.master
    @ebay_channel = variant.ebay_channel
    @web_channel = variant.web_channel
  end

  def request(path, body = {})
    HTTParty.post(
      "#{ENV['PIPELINE_URL']}#{path}",
      body: body.to_json,
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    ).parsed_response
  end


  #####################
  # getting status from pipeline
  #####################

  def status
    begin
      response = request("/api/ebay/products/#{variant.ebay_product_pipeline_id}/status")
      data = response["data"]
      item_id = data["itemId"]
      status = data["status"]
      product_status = data["productStatus"]
      message = data["syncMessage"]

      sync_details = data["syncDetails"]
      status_changed_at = data["statusChangedAt"].to_datetime.to_s
      errors = sync_details["errors"]
      warnings = sync_details["warnings"]

      ebay_last_push_success = nil

      # if is completed and pulled, the db should be updated with pipeline data
      # so we return here to not save any status data because read calls this again
      # and will appropriately set the sync status after saving
      if status == "complete" && product_status == "pulled"
        read
        return
      end

      if status == "failed"
        message = errors.present? && errors.any? ? errors.join("\n") : message
        ebay_last_push_success = false
      elsif status == "complete"
        ebay_last_push_success = true
      end

      ebay_product_pipeline_data = {
        status: status,
        product_status: product_status,
        message: message,
        warnings: warnings && warnings.length > 0 ? warnings.join("\n") : "",
        status_changed_at: status_changed_at
      }

      if item_id && variant.item_id.blank?
        variant.update_columns(item_id: item_id)
      end

      new_data = variant.ebay_product_pipeline_data.merge(ebay_product_pipeline_data.stringify_keys)
      variant.update_columns(
        ebay_product_pipeline_data: new_data,
        ebay_last_push_success: ebay_last_push_success,
      )
    rescue => e
      puts e
    end
  end

  #####################
  # pushing to pipeline
  #####################

  # determining if a product should be created or updated on the pipeline
  def push
    if variant.active? && variant.published_ebay
      if variant.ebay_product_pipeline_id
        update
      else
        create
      end
    end
  end

  # pushes payload to the pipeline and triggers add item request
  def create
    # rando begin rescue to capture network errors
    begin
      response = request("/api/ebay/products/create", payload)
      if response["data"] && response["data"]["id"]
        variant.update(	
          ebay_product_pipeline_id: response["data"]["id"],
        )
      end
    rescue => e
      puts e
    end
  end

  # pushes payload to the pipeline and triggers revise item request
  def update
    # rando begin rescue to capture network errors
    begin
      response = request("/api/ebay/products/#{variant.ebay_product_pipeline_id}/update", payload)
    rescue => e
      puts e
    end
  end

  # pushes item id to the pipeline and triggers sync
  def build
    # rando begin rescue to capture network errors
    begin
      response = request("/api/ebay/products/build", { itemId: variant.item_id })
      if response["data"] && response["data"]["id"]
        variant.update(	
          ebay_product_pipeline_id: response["data"]["id"],
        )
      end
    rescue => e
      puts e
    end
  end

  #####################
  # pulling from pipeline
  #####################

  # flags product on pipeline to sync data from ebay
  def pull
    # rando begin rescue to capture network errors
    begin
      response = request("/api/ebay/products/#{variant.ebay_product_pipeline_id}/pull2")
      status()
    rescue => e
      puts e
    end
  end

  # reads date from pipeline and updates db
  def read
    begin
      response = request("/api/ebay/products/#{variant.ebay_product_pipeline_id}")

      data = response["data"]
      
      images = data["images"]

      read_product(data)
      read_channel(data)
      read_sku(data, variant)
      read_price(data, variant)
      read_barcodes(
        {
        EAN: data["ean"],
        UPC: data["upc"],
        GTIN: data["gtin"],
        ISBN: data["isbn"],
        }, 
        variant
      )
      read_properties(data["properties"], variant)

      read_shipping(data["shippingServices"])

      if (variant.build_from_ebay)
        read_images(data)
      end

      # reading main variant specific images from ebay specific images
      read_variant_images(data["specificImages"], variant)

      read_variants(data)

      request("/api/ebay/products/#{variant.ebay_product_pipeline_id}/read")

      variant.update(build_from_ebay: false)

      status()
    rescue => e
      puts e
    end
  end

  def read_sku(data, v)
    sku = data["sku"]
    if sku.present? 
      if sku != v.sku && v.sku == v.item_id
        v.update(sku: sku)
      end
      if sku != v.sku
        v.update(ebay_sku: sku)
      end
    end
  end

  # the main product details for the master/main variant
  def read_product(data)
    brand_name = data["brand"]
    
    title = data["title"]
    mpn = data["mpn"]
    current_stock = data["quantity"]
    weight = data["weight"]
    x_dimension = data["packageWidth"]
    y_dimension = data["packageLength"]
    z_dimension = data["packageDepth"]

    # if brand_name.present?
    #   brand = C::Brand.find_or_create_by(name: brand_name)
    #   master.update(brand_id: brand.id, manufacturer_id: brand.id)
    # end

    variant.update(
      mpn: mpn,
      current_stock: current_stock,
      weight: weight,
      published_ebay: true,
      status: :active,
    )

    if variant.name.blank? && title.present?
      variant.update(name: title)
    end

    if C.ebay_package_details.include?("width") 
      variant.update(x_dimension: x_dimension)
    end
    if C.ebay_package_details.include?("height")
      variant.update(y_dimension: y_dimension)
    end
    if C.ebay_package_details.include?("depth") 
      variant.update(z_dimension: z_dimension)
    end
  end

  def read_price(data, v)
    price =  data["price"]
    currency =  data["currency"]

    local_price = v.ebay_price

    # For weird scenario where main variant doesn't have an associated eBay price
    if local_price.blank?
      local_price = v.build_ebay_price
    end

    price_hash = { with_tax: price }
    price_hash[:tax_rate] = 0 if C.ex_vat && price < C.ex_vat_threshold

    local_price.update(price_hash)

    if v.retail_price.with_tax.zero?
      v.retail_price.update(price_hash) 
    end
  end
  
  def read_channel(data)
    # general channel details
    title = data["title"]
    sub_title = data["subTitle"]
    condition = data["conditionId"]
    condition_description = data["conditionDescription"]
    description = data["description"]
    postcode = data["postCode"]
    duration = data["listingDuration"]
    country = data["country"]
    uses_ebay_catalogue = !!data["usesEbayCatalogue"]
    
    domestic_shipping_type = data["shippingType"]
    global_shipping = !!data["globalShipping"]
    click_collect_collection_available = !!data["clickAndCollect"]
    pickup_in_store = !!data["pickupInStore"]
    dispatch_time = data["dispatchTime"]
    package_type = data["packageType"]
    
    payment_method_paypal = !!data["paymentPaypal"]
    payment_method_escrow = !!data["paymentEscrow"]
    payment_method_cheque = !!data["paymentCheque"]
    payment_method_postal = !!data["paymentPostal"]
    payment_method_cc = !!data["paymentCC"]
    payment_method_money_order = !!data["paymentMoneyOrder"]
    payment_method_other = !!data["paymentOther"]
    
    returns_accepted = !!data["returnsAccepted"]
    returns_description = data["returnsDescription"]
    restocking_fee_value_option = data["restockingFeeValueOption"]
    refund_option = data["refundOption"]
    returns_within = data["returnsWithinOption"]
    returns_cost_paid_by = data["returnCostPaidByOption"]
    
    warranty_offered = !!data["warrantyOffered"]
    warranty_type = data["warrantyTypeOption"]
    warranty_duration = data["warrantyDurationOption"]
    
    
    ### this call somehow regexes out html and other junk to return rich text
    desc, text1, text2 = ebay_channel.subbed_text(description)

    category_id = data["categoryPrimary"]

    if category = C::EbayCategory.find_by(category_id: category_id)
      ebay_channel.update(ebay_category: category)
    end
    
    ebay_channel.update({
      name: title,
      sub_title: sub_title,
      condition: condition,
      condition_description: condition_description,
      description: desc,
      wrap_text_1: text1,
      wrap_text_2: text2,
      postcode: postcode,
      duration: duration,
      country: country,
      uses_ebay_catalogue: uses_ebay_catalogue,
      domestic_shipping_type: domestic_shipping_type,
      global_shipping: global_shipping,
      click_collect_collection_available: click_collect_collection_available,
      pickup_in_store: pickup_in_store,
      dispatch_time: dispatch_time,
      package_type: package_type,
      payment_method_paypal: payment_method_paypal,
      payment_method_escrow: payment_method_escrow,
      payment_method_cheque: payment_method_cheque,
      payment_method_postal: payment_method_postal,
      payment_method_cc: payment_method_cc,
      payment_method_money_order: payment_method_money_order,
      payment_method_other: payment_method_other,
      returns_accepted: returns_accepted,
      returns_description: returns_description,
      restocking_fee_value_option: restocking_fee_value_option,
      refund_option: refund_option,
      returns_within: returns_within,
      returns_cost_paid_by: returns_cost_paid_by,
      warranty_offered: warranty_offered,
      warranty_type: warranty_type,
      warranty_duration: warranty_duration,
    })
  end

  def read_barcodes(barcodes_map, v)
    barcodes_map.each do |symbology, value|
      if symbology == :EAN
        if value == v.barcode_does_not_apply_text
          v.update(no_barcodes: true)
          return
        else
          v.update(no_barcodes: false)
        end
      end

      if value.blank?
        next
      end

      barcode = v.barcodes.find_or_create_by(symbology: symbology) do |b|
        b.value = value
      end
      barcode.update(value: value)
    end
  end

  def read_properties(properties_map, v)
      properties_map.each do |key, value|
      property_key = C::Product::PropertyKey.find_or_create_by(key: key)
      property_value = v.property_values.find_by(property_key_id: property_key.id)

      if property_value.present?
        property_value.update(value: value)
      else
        v.property_values.create(property_key_id: property_key.id, value: value)
      end
    end
  end

  def read_shipping(shipping_services)
    if shipping_services.any?
      ebay_channel.update(no_shipping_options: false)

      locations = []

      shipping_services.each do |shipping_service|
        delivery_service = find_or_create_delivery_service(shipping_service["service"])
        local_shipping = ebay_channel.shipping_services.find_or_create_by(delivery_service: delivery_service)

        local_shipping.update(
          cost: shipping_service["cost"],
          additional_cost: shipping_service["additionalCost"],
          international: !!shipping_service["international"]
        )

        if shipping_service["locations"] && shipping_service["locations"]["locations"]
          shipping_service["locations"]["locations"].each { |l| locations.push(l) }
        end
      end

      locations.each do |l|
        location = C::Product::Channel::Ebay::ShipToLocation.code_to_location(l)
        if location.present?
          ebay_channel.ship_to_locations.find_or_create_by(location: location) 
        end
      end
    else
      ebay_channel.update(no_shipping_options: true)
    end
  end

  def read_images(data)
    image_urls = data["images"].map { |image| image["url"].gsub('$_1', '$_57') }
    variants = data["variants"]
    variant_image_urls = []

    variants.each do |v|
      v["images"].each do |image|
        variant_image_urls.push(image["url"].gsub('$_1', '$_57'))
      end
    end

    image_urls_to_build = (image_urls + variant_image_urls).uniq

    image_urls_to_build.each do |image_url|
      begin
        # Begin rescue to block to prevent errors when 403 for unavailable asset
        image = master.images.create!(remote_image_url: image_url)

        if image_urls.include?(image_url)
          index = image_urls.index(image_url)
          channel_image = master.ebay_channel.channel_images.create!(image: image)
          weight = channel_image._weight
          weight.update(value: index)
        end

      rescue => e
        puts e
      end
    end
  end

  def read_variants(data)
    ebay_variants = data["variants"]

    ebay_variants.each do |ebay_variant|
      v = master.variants.find_or_create_by(sku: ebay_variant["sku"])

      v.update(
        current_stock: ebay_variant["quantity"], 
        published_ebay: true,
        status: :active,
      )

      price_map = {
        "price" => ebay_variant["price"],
        "currency" => data["currency"],
      }

      barcodes_map = {
        EAN: data["ean"],
        UPC: data["upc"],
        ISBN: data["isbn"],
      }

      read_price(price_map, v)
      read_properties(ebay_variant["properties"], v)
      read_barcodes(barcodes_map, v)
      read_variant_images(ebay_variant["images"], v)
    end
  end

  def read_variant_images(images, v)
    images.each do |image|
      picture_url = image["url"]
      picture_name = picture_url.split('/').last
      
      master.images.pluck(:id, :image).each do |id, image|
        if picture_name.include?(image)
          v.variant_images.find_or_create_by(image_id: id) 
        end
      end
    end
  end

  def find_or_create_delivery_service(ebay_alias)
    if delivery_service = C::Delivery::Service.ebay.find_by(ebay_alias: ebay_alias)
      return delivery_service
    end

    provider = C::Delivery::Provider.find_or_create_by(name: 'eBay Provider')

    C::Delivery::Service.create(
      name: ebay_alias,
      ebay_alias: ebay_alias,
      provider: provider, 
      channel: :ebay
    )
  end

  #####################
  # things for serializing commercity data to pipeline
  #####################

  def payload
    {
      sku: variant.ebay_sku,
      itemId: variant.item_id,
      title: variant.ebay_title_fallback,
      description: ebay_channel.subbed_shop_wrap(variant.channel_description_fallback('ebay'), variant.price(channel: :ebay, fallback: :web)),
      subTitle: ebay_channel.sub_title,
      mpn: variant.mpn,
      brand: master&.brand&.name,
      ean: get_barcode(variant, "EAN"),
      upc: get_barcode(variant, "UPC"),
      gtin: get_barcode(variant, "GTIN"),
      isbn: get_barcode(variant, "ISBN"),
      categoryPrimary: ebay_channel.category_fallback&.to_s,
      price: get_price(variant).fractional.to_f / 100,
      currency: get_price(variant).currency.id.to_s.upcase,
      conditionId: ebay_channel.condition,
      conditionDescription: ebay_channel.condition_description,
      country: ebay_channel.country,
      listingDuration: ebay_channel.duration,
      listingType: 'FixedPriceItem',
      usesEbayCatalogue: !!ebay_channel.uses_ebay_catalogue,
      paymentPaypal: !!ebay_channel.payment_method_paypal,
      paymentEscrow: !!ebay_channel.payment_method_escrow,
      paymentCheque: !!ebay_channel.payment_method_cheque,
      paymentPostal: !!ebay_channel.payment_method_postal,
      paymentCC: !!ebay_channel.payment_method_cc,
      paymentMoneyOrder: !!ebay_channel.payment_method_money_order,
      paymentOther: !!ebay_channel.payment_method_other,
      paymentPickup: !!ebay_channel.pickup_in_store,
      paypalEmail: C.ebay_paypal,
      postCode: ebay_channel.postcode,
      quantity: variant.quantity_check,
      dispatchTime: ebay_channel.dispatch_time || 0,
      weight: variant.weight.present? && C.ebay_package_details.include?("weight") ? variant.weight.to_f : nil,
      shippingType: ebay_channel.domestic_shipping_type,
      packageType: ebay_channel.package_type,
      packageDepth: variant.z_dimension.present? && C.ebay_package_details.include?("depth") ? variant.z_dimension.to_f : nil,
      packageLength: variant.y_dimension.present? && C.ebay_package_details.include?("height") ? variant.y_dimension.to_f : nil,
      packageWidth: variant.x_dimension.present? && C.ebay_package_details.include?("width") ? variant.x_dimension.to_f : nil,
      pickupInStore: ebay_channel.pickup_in_store?,
      clickAndCollect: ebay_channel.click_collect_collection_available?,
      globalShipping: ebay_channel.global_shipping,
      properties: variant.properties,
      classifierProperty: ebay_channel.classifier_property_key.present? ? ebay_channel.classifier_property_key.key : C.ebay_variant_classifier,
      returnsAccepted: !!ebay_channel.returns_accepted,
      returnsDescription: ebay_channel.returns_description,
      restockingFeeValueOption: ebay_channel.restocking_fee_value_option,
      refundOption: ebay_channel.refund_option,
      returnsWithinOption: ebay_channel.returns_within,
      returnCostPaidByOption: ebay_channel.returns_cost_paid_by,
      warrantyOffered: ebay_channel.warranty_offered ? ebay_channel.warranty_offered : nil,
      warrantyTypeOption: ebay_channel.warranty_type,
      warrantyDurationOption: ebay_channel.warranty_duration,
      # shippingServices: get_shipping_services(),
      shippingServices: [],
      variants: get_variants(),
      images: get_images(),
      specificImages: variant.images.map.with_index { |image, i|
        next if image&.image&.url.blank?
        {
          url: image.image.url,
          weight: i,
        }
      }.compact
    }.compact
  end


  def get_barcode(v, symbology)
    # this func is used for variant in attr_accessor and as well as sibiling variants
    # so arg is valled v instead of variant to avoid shadowing variant attr_accessor
    if v.no_barcodes
      if symbology == "EAN"
        v.barcode_does_not_apply_text
      else
        nil
      end
    else
      barcode = v.barcodes.find_by(symbology: symbology)
      barcode ? barcode.value : nil
    end
  end

  def get_price(v, fallback_v=nil)
    # this func is used for variant in attr_accessor and as well as sibiling variants
    # so arg is valled v instead of variant to avoid shadowing variant attr_accessor
    p = v.price(channel: :ebay,  fallback: :web)

    if p.fractional.zero? && fallback_v.present?
      price(fallback_v)
    else
      p
    end
  end

  def get_shipping_services
    services = ebay_channel.domestic_services + ebay_channel.international_services
    services.map do |service|
      next if service.delivery_service.ebay_alias.blank?
      international = !!service.international
      cost = service.default_cost.is_a?(Money) ? service.default_cost.fractional.to_f / 100 : service.default_cost.to_f
      additional_cost = service.default_additional_cost.is_a?(Money) ? service.default_additional_cost.fractional.to_f / 100 : service.default_additional_cost.to_f
      {
        priority: 1,
        service: service.delivery_service.ebay_alias,
        cost: cost,
        additionalCost: additional_cost,
        international: international,
        locations: international ? { locations: ebay_channel.ship_to_locations.map { |l| l.code } } : nil
      }.compact
    end.compact
  end

  def get_variants
    variant.sibling_variants.where(published_ebay: true).map do |v| 
      {
        sku: v.sku,
        price: get_price(v, variant).fractional.to_f / 100,
        quantity: v.quantity_check,
        ean: get_barcode(v, "EAN"),
        upc: get_barcode(v, "UPC"),
        gtin: get_barcode(v, "GTIN"),
        isbn: get_barcode(v, "ISBN"),
        properties: v.properties,
        images: v.images.map.with_index { |image, i|
          next if image&.image&.url.blank?
          {
            url: image.image.url,
            weight: i,
          }
        }.compact
      }.compact
    end
  end

  def get_images()
    list = ebay_channel.channel_images.ordered.map { |image| image.image }

    list.map.with_index { |image, i|
      next if image&.image&.url.blank?
      {
        url: image.image.url,
        weight: i,
      }
    }.compact.take(12)
  end

end

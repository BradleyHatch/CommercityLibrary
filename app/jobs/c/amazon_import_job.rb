# frozen_string_literal: true

module C
  class AmazonImportJob
    include SuckerPunch::Job

    XSD_PATH = File.join(C::Engine.root, 'app', 'assets', 'xsds')
    COLOR_MAP_REGEX = /beige|black|blue|brass|bronze|brown|chrome|clear|gold|gray|green|multi-coloured|natural|orange|pink|purple|red|silver|sunburst|white|yellow/

    def get_schema(name)
      Nokogiri::XML(File.open(File.join(XSD_PATH, "#{name}.xsd")))
    end

    def xpath(schema, query)
      schema.xpath(query, schema.collect_namespaces)
    end

    def pull_product_categories
      schema = get_schema('Product')
      query = '//xsd:element[@name="ProductData"]//xsd:element'
      xpath(schema, query).map do |cat|
        cat = cat.attribute('ref').value
        { cat: cat, values: pull_product_types(cat) }
      end
    end

    def pull_product_types(cat)
      if cat == 'Clothing'
        pull_clothing_types(cat)
      elsif cat == 'ClothingAccessories'
        pull_flat_types(cat)
      else
        pull_standard_product_types(cat)
      end
    end

    def pull_clothing_types(cat)
      schema = get_schema(cat)
      query = '//xsd:element[@name="ClothingType"]//xsd:enumeration'
      xpath(schema, query).map do |type|
        type = type.attribute('value').value
        { type: type, values: pull_flat_attrs(cat) }
      end
    end

    def pull_flat_types(cat)
      [{ type: 'ClothingAccessory', values: pull_flat_attrs(cat) }]
    end

    def pull_standard_product_types(cat)
      schema = get_schema(cat)
      query = '//xsd:element[@name="ProductType"]//xsd:element[@ref]'
      xpath(schema, query).map do |type|
        type = type.attribute('ref').value
        { type: type, values: pull_product_attrs(cat, type) }
      end
    end

    # TODO: Deal with flat and clothing attrs

    def pull_flat_attrs(cat)
      schema = get_schema(cat)
      query = "//xsd:element[@name=\"ClassificationData\"]/xsd:complexType/xsd:sequence/xsd:element"
      xpath(schema, query).map do |el|
        el.attribute('name')&.value
      end.compact
    end

    def pull_product_attrs(cat, type)
      schema = get_schema(cat)
      query = "//xsd:element[@name=\"#{type}\"]/xsd:complexType/xsd:sequence/xsd:element"
      xpath(schema, query).map do |el|
        el.attribute('name')&.value
      end.compact
    end

    def seed_db_with_cats(cats)
      cats ||= ['MusicalInstruments']
      cats.each do |cat|
        logger.info "Category: #{cat}"
        cat_hash = pull_product_types(cat)
        c = C::AmazonCategory.find_or_create_by(name: cat)
        cat_hash.each do |h|
          logger.info "  Type: #{h[:type]}"
          p = c.amazon_product_types.find_or_create_by(name: h[:type])
          h[:values].each do |value|
            logger.info "    Attribute: #{value}"
            p.amazon_product_attributes.find_or_create_by(name: value)
          end
        end
      end
    end
  end
end

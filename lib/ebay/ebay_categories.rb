# frozen_string_literal: true

# First method takes category id and returns info about category
# Second method simply returns all of the categories from ebay
# Third method calls the second, and then creates a local record for each
# category and then creates a hierarchical structure

module EbayCategories
  extend ActiveSupport::Concern

  def request_get_category_specifics(val)
    call = 'GetCategorySpecifics'
    request = EbayTrader::Request.new(call) do
      WarningLevel 'High'
      CategorySpecific do
        CategoryID val.flatten[1]
      end
    end
    request.response_hash
  end

  def request_get_categories
    request = EbayTrader::Request.new('GetCategories') do
      # CategoryParent ARGV.first unless ARGV.empty?
      DetailLevel 'ReturnAll'
      LevelLimit 5
      ViewAllNodes true
    end
    request.response_hash[:category_array][:category]
  end

  def categories_import
    cats = request_get_categories

    # category_name
    # category_id
    # category_parent_id
    # category_level

    cats.each do |cat|
      local_cat = C::EbayCategory.find_or_create_by(category_id: cat[:category_id]) do |c|
        c.best_offer_enabled = cat[:best_offer_enabled]
        c.auto_pay_enabled = cat[:auto_pay_enabled]
        c.category_level = cat[:category_level]
        c.category_name = cat[:category_name]
        c.category_parent_id = cat[:category_parent_id]
      end
      local_cat.update!(
        best_offer_enabled: cat[:best_offer_enabled],
        auto_pay_enabled: cat[:auto_pay_enabled],
        category_level: cat[:category_level],
        category_name: cat[:category_name],
        category_parent_id: cat[:category_parent_id]
      )
    end

    # Used to be in model but not used on sie so moved to here :/
    C::EbayCategory.find_each do |category|
      unless category.category_parent_id == category.category_id
        category.update!(
          parent_id: C::EbayCategory.find_by(
            category_id: category.category_parent_id
          ).id
        )
      end
    end
  end

  # Builds local product categories from an eBay listing hash after a product
  # has been synced
  # Assume that all eBay categories have been seeded
  def create_product_category(local_ebay_category, child_product_category=nil)
    return unless local_ebay_category
    product_category = C::Category.find_or_create_by!(name: local_ebay_category.category_name,
                                                      ebay_category_id: local_ebay_category.id)
    child_product_category&.update(parent: product_category)
    create_product_category(local_ebay_category.parent, product_category) if local_ebay_category.parent
  end

  def create_product_categorizations(master)
    categories = C::Category.where(ebay_category_id: master.ebay_channel.ebay_category_id)
    categories.each do |category|
      categorize_product(master, category)
    end
  end

  def categorize_product(master, category)
    master.categorizations.find_or_create_by!(category: category)
    categorize_product(master, category.parent) if category.parent
  end

  def request_store_categories
    request = EbayTrader::Request.new('GetStore') do
      WarningLevel 'High'
      CategoryStructureOnly true
    end
    request.response_hash
  end

  def store_categories_dict
    response = request_store_categories
    dict = {}
    return dict if response[:store].blank? || response[:store][:custom_categories].blank?
    to_array(response[:store][:custom_categories][:custom_category]).each do |custom_category|
      dict = dict.merge(traverse_categories(custom_category))
    end
    dict
  end

  def traverse_categories(custom_category, parent_id=nil)
    dict = {}
    dict[custom_category[:category_id].to_s] = [custom_category[:name].to_s, parent_id, custom_category[:order]]
    return dict if custom_category[:child_category].blank?
    to_array(custom_category[:child_category]).each do |child_category|
      dict = dict.merge(traverse_categories(child_category, custom_category[:category_id].to_s))
    end
    dict
  end

  def build_store_categories(categories_dict)
    categories_dict.each do |id, values|
      local_category = C::Category.find_or_create_by(name: values[0])
      local_category.update(ebay_store_category_id: id.to_s, weight: values[2])

      next unless values[1]
      parent_info = categories_dict[values[1].to_s]

      next unless parent_info
      parent_category = C::Category.find_or_create_by(name: parent_info[0])
      parent_category.update(ebay_store_category_id: parent_info[1].to_s, weight: parent_info[2])
      local_category.update(parent_id: parent_category.id)
    end
  end

end

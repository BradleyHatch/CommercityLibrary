# frozen_string_literal: true

module C
  class EbayCategory < ApplicationRecord
    acts_as_tree

    validates :category_name, presence: true
    validates :category_id, presence: true
    validates :category_parent_id, presence: true
    validates :category_level, presence: true

    def self.select_setup(params, obj)
      case params[:check]
      when 'check'
        if obj.ebay_category_id.present?
          cats = []
          cats << (current_cat = C::EbayCategory.find(obj.ebay_category_id))
          while current_cat.parent
            current_cat = current_cat.parent
            cats.unshift(current_cat)
          end
        end
      when 'get'
        inc = params[:i].to_i
        ebay_cat = C::EbayCategory.find(params[:catID].to_i)
      end
      { check: params[:check], save_name: params[:save_name], cats: cats, inc: inc, ebay_cat: ebay_cat }
    end
  end

end

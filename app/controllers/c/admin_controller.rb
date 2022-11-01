# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  class AdminController < C::ApplicationController
    check_authorization unless: :no_authorisation_test
    config.cache_store = :null_store

    before_action :authenticate_user!
    before_action :set_paper_trail_whodunnit
    before_action :use_raw_id!

    def edit; end

    def new; end

    def sage; end

    def debug; end

    def no_images_csv
      masters = C::Product::Master.left_joins(:images).group(:id).having('COUNT(c_product_images.id) < 1')
      masters = masters.left_joins(:variants).group(:id).where('c_product_variants.current_stock > 0') if params['in_stock']
      send_csv(masters, "#{'in_stock_' if params['in_stock']}products_with_no_images.csv")
    end

    def no_desc_csv
      masters = C::Product::Master.joins(:variants).joins(:web_channel).group(:id).where("COALESCE(c_product_variants.description, '') = ''").where(("COALESCE(c_product_channel_webs.description, '') = ''"))
      send_csv(masters, 'products_with_no_desc.csv')
    end

    def active_weights_csv
      master_ids = C::Product::Variant.where(weight: 0, status: :active).pluck(:master_id).uniq
      masters = C::Product::Master.where(id: master_ids)
      send_csv(masters, 'active_products_with_no_weight.csv')
    end

    def all_weights_csv
      master_ids = C::Product::Variant.where(weight: 0).pluck(:master_id).uniq
      masters = C::Product::Master.where(id: master_ids)
      send_csv(masters, 'all_products_with_no_weight.csv')
    end

    def save_price_change_reason
      price_change = C::PriceChange.find_by(id: params[:id])
  
      if price_change.blank?
        render json: { success: false, message: "Error saving reason: price change reason" }
        return
      end
  
      price_change.update(reason: params[:value])
  
      render json: { success: true, message: "Price change reason saved successfully" }
    end

    private

    def send_csv(masters, name)
      csv_obj = CSV.generate do |csv|
        csv << ['Name', 'SKU', 'MPN', 'Brand', 'Manufacturer']
        masters.each do |master|
          csv << [master.main_variant.name, master.main_variant.sku, master.main_variant.mpn, master&.brand&.name, master&.manufacturer&.name]
        end
      end

      send_data csv_obj,
                type: 'text/csv; charset=iso-8859-1; header=present',
                disposition: "attachment; filename='#{name}'"
    end

    def no_authorisation_test
      devise_controller? ||
        (controller_name == 'admin' && %w[dashboard debug no_images_csv no_desc_csv all_weights_csv active_weights_csv save_price_change_reason].include?(action_name)) ||
        action_name == 'sage'
    end

    def use_raw_id!
      ApplicationRecord.use_raw_id!
    end

    def ajax_form
      respond_to do |format|
        format.html
        format.js { render 'quick_edit' }
      end
    end

    def filter_and_paginate(collection, default_sort='id asc', per_page=30)
      @q = collection.ransack(params[:q])
      @q.sorts = default_sort if @q.sorts.empty?
      @q.result.paginate(page: params[:page], per_page: per_page)
    end
  end
end

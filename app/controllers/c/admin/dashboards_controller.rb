# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class DashboardsController < AdminController
      load_and_authorize_resource class: C::Product::Variant
      load_and_authorize_resource class: C::Order::Sale
      load_and_authorize_resource class: C::Order::Item

      def index
        @from = (Time.now.beginning_of_day - 1.years).strftime('%FT%T')
        @to = Time.now.end_of_day.strftime('%FT%T')
        @frequency = "months"
        @variant_ids = nil
        @channel = nil
      end

      sample = {"variant_id"=>"39", "channel"=>"web", "date_from"=>"2020-04-04", "date_to"=>"2020-03-31", "frequency"=>"months"} 

      # @frequency = days | weeks | months
      # @channel = web | amazon | ebay
      def list
        @from = params[:date_from].present? ? params[:date_from] : (Time.now - 1.years).strftime('%F %T')
        @to = params[:date_to].present? ? params[:date_to] : Time.now.strftime('%F %T')
        @frequency = params[:frequency].present? ? params[:frequency] : "months"
        @variant_ids = nil
        @channel = params[:channel].present? ? params[:channel] : nil
        
        variant_ids = []

        if params[:variant_ids].present?
          @variant_ids = params[:variant_ids]
          variant_ids = params[:variant_ids]
        else
          variant_ids = C::Product::Variant.active.pluck(:id)
        end

        variants = C::Product::Variant.where(id: variant_ids).select(:id, "CONCAT(sku, ': ', name) AS sku_name", :created_at)

        # 1/2 status is awaiting_dispatch/dispatched
        items = C::Order::Item.where(product_id: variant_ids).order(created_at: :desc).joins(:order).group(:id).where('c_order_items.created_at >= ?', @from).where('c_order_items.created_at <= ?', @to).where(c_order_sales: { status: [1, 2] })

        #  0/1/2 is amazon channel/ebay channel/web channel
        if @channel.present?
          if @channel == "web"
            items = items.where(c_order_sales: { channel: 2 })
          elsif @channel == "amazon"
            items = items.where(c_order_sales: { channel: 0 })
          elsif @channel == "ebay"
            items = items.where(c_order_sales: { channel: 1 })
          end
        end

        date_range = []

        if @frequency == "days"
          date_range = datetime_sequence(@from.to_datetime.beginning_of_day, @to.to_datetime.beginning_of_week + 1.days, 1.days)
        elsif @frequency == "weeks"
          date_range = datetime_sequence(@from.to_datetime.beginning_of_week, @to.to_datetime.beginning_of_week + 1.weeks, 1.weeks)
        else
          date_range = datetime_sequence(@from.to_datetime.beginning_of_month, @to.to_datetime.beginning_of_month + 1.months, 1.months)
        end

        items = items.to_a

        @data = variants.map do |variant|
          name = variant["sku_name"]

          records = items.select { |item| item.product_id == variant.id }

          records = records.map { |r| [r.created_at, r.quantity] }

          data = date_range.each_with_index.map  do |date, i|
            matching_records = records.select do |record| 
              if i == date_range.length - 1
                record[0] >= date
              else
                record[0].between?(date, date_range[i+1])
              end
            end

            if matching_records.any?
              [date.strftime('%F'), matching_records.map{ |c, q| q }.sum]
            else
              [date.strftime('%F'), 0]
            end
          end

          { name: name, data: data}
        end

        render :index      
      end

      private

      def datetime_sequence(start, stop, step)
        dates = [start]
        while dates.last < (stop - step)
          dates << (dates.last + step)
        end 
        return dates
      end 
    end
  end
end

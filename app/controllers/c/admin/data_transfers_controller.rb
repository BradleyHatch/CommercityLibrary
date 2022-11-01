# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    class DataTransfersController < AdminController
      load_and_authorize_resource class: C::DataTransfer

      def index
        @data_transfers = @data_transfers.csv
      end

      def show
        @page = params[:page].to_i || 0
        @row_count = @data_transfer.parsed_file.size
        @page_links = *(0..@row_count/50)

        @results_hash = @data_transfer.results_hash(true, false, @page)
      rescue => e
        flash.now[:error] = "Error: Is file CSV? (#{e})"
        @data_transfers = [@data_transfer]
        render :index
      end

      def new; end

      def update
        if @data_transfer.update(data_transfer_params)
          redirect_to @data_transfer, notice: 'Import scheduled'
        else
          @results_hash = @data_transfer.results_hash true
          render :show
        end
      end

      def create
        @data_transfer = C::DataTransfer.new(data_transfer_params)
        if @data_transfer.save
          redirect_to @data_transfer
        else
          render :new
        end
      end

      def csv_import
        C::CsvImport.perform_later(@data_transfer)
        redirect_to product_masters_path, notice: 'importing'
      end

      def destroy
        @data_transfer.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to [:data_transfers] }
        end
      end

      private

      def data_transfer_params
        params.require(:data_transfer).permit(:file, :import_type, :name, :body, :import_at, :replace_images)
      end
    end
  end
end

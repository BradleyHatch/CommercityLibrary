# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class BarcodesController < AdminController
      load_and_authorize_resource class: C::Product::Barcode

      def index
        @barcodes = @barcodes.unassigned
      end

      def create
        if @barcode.save
          flash[:success] = 'Barcode saved'
          redirect_to action: :index
        else
          render :new
        end
      end

      def update
        if @barcode.update(barcode_params)
          flash[:success] = 'Barcode updated'
          redirect_to action: :index
        else
          render :edit
        end
      end

      def destroy
        if @barcode.destroy
          flash[:success] = 'Barcode deleted'
          redirect_to action: :index
        else
          flash.now[:error] = 'Barcode could not be deleted'
          render :edit
        end
      end

      def csv_import
        @output = CSV.parse(params[:import_file].read.force_encoding('utf-8'),
                            headers: true)
        @barcodes = @output.map do |row|
          C::Product::Barcode.find_or_initialize_by(value: row[0],
                                                    symbology: row[1])
        end

        @new_barcodes = @barcodes.select(&:new_record?)
        @invalid_barcodes = @new_barcodes.map.with_index do |barcode, i|
          [barcode, i] unless barcode.save
        end.compact
      end

      private

      def barcode_params
        params.require(:product_barcode).permit(
          :id, :value, :symbology
        )
      end
    end
  end
end

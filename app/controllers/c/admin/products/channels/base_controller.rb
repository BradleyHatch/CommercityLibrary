# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      module Channels
        class BaseController < AdminController
          before_action :set_master, only: %i[show edit update]
          before_action :set_variant, only: %i[show edit update]

          private

          def set_master
            @master = C::Product::Master.find(params[:master_id])
          end

          def set_variant
            @variant = @master.variants.find(params[:product_variant_id])
          end
        end
      end
    end
  end
end

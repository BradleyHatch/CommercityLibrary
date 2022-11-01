# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Products
      class FeaturesController < AdminController
        load_and_authorize_resource class: C::Product::Feature

        def index
          @features = filter_and_paginate(@features, 'name asc', 250)
        end

        def create
          if @feature.save
            redirect_to product_features_path
          else
            @feature.price = C::Price.new
            render :new
          end
        end

        def update
          if @feature.update(feature_params)
            redirect_to product_features_path
          else
            render :edit
          end
        end

        def destroy
          @feature.destroy
          redirect_to product_features_path, notice: 'Feature Deleted'
        end

        private

        def feature_params
          params.require(:product_feature).permit(:name, :image, :body, :feature_type, :link)
        end
      end
    end
  end
end

# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class TestimonialsController < AdminController
      load_and_authorize_resource class: C::Testimonial

      def index
        @testimonials = filter_and_paginate(@testimonials, 'created_at desc')
      end

      def create
        @testimonial = C::Testimonial.new(testimonial_params)
        if @testimonial.save
          redirect_to testimonials_path, notice: 'Testimonial created'
        else
          render :new
        end
      end

      def update
        if @testimonial.update(testimonial_params)
          redirect_to testimonials_path, notice: 'Testimonial updated'
        else
          render :edit
        end
      end

      def destroy
        @testimonial.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to testimonials_path }
        end
      end

      private

      def testimonial_params
        params.require(:testimonial).permit(:author, :quote, :title)
      end
    end
  end
end

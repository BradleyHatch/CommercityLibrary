# frozen_string_literal: true

module C
  module Channel
    extend ActiveSupport::Concern

    included do
      belongs_to :master
      has_many :channel_images, as: :channel
      has_many :images, lambda {
        includes(:_weight).order('c_weights.value asc')
      }, through: :channel_images

      common_attributes :name, :description

      def testing_publishability?
        @testing_publishability
      end

      def publishable?
        @testing_publishability = true
        valid?
      end

      def short_description
        if description.length > 150
          description.truncate(150)
        else
          description
        end
      end
    end

    class_methods do
      def common_attribute(name)
        define_method(name) do |*args|
          super(*args).present? ? super(*args) : master&.send(name)
        end
        define_method "has_own_#{name}?" do
          self[name].present?
        end
        define_method "own_#{name}" do
          self[name]
        end
      end

      def common_attributes(*names)
        names.each do |name|
          common_attribute name
        end
      end

      def publishable?(&block)
        with_options if: :testing_publishability?, &block
      end
    end
  end
end

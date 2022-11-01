# frozen_string_literal: true

module C
  class BasePresenter
    def initialize(object, template)
      @object = object
      @template = template
    end

    def self.presents(name)
      define_method(name) do
        @object
      end
    end

    def h
      @template
    end

    def method_missing(*args, &block)
      @template.send(*args, &block)
    end

    def respond_to_missing?(method_name, _include_private = false)
      super
    end
  end
end

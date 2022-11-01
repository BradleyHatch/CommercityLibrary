# frozen_string_literal: true

module C
  module PresenterHelper
    def presenter(obj, cls=nil)
      @_presenters ||= {}
      @_presenters[obj.object_id] ||= begin
        cls ||= "#{obj.class}Presenter".constantize
        cls.new(obj, self)
      end
    end
  end
end

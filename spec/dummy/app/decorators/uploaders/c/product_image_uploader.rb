# frozen_string_literal: true

C::ProductImageUploader.class_eval do
  storage :fog
end

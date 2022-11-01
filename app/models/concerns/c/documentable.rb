# frozen_string_literal: true

module C
  module Documentable
    extend ActiveSupport::Concern

    included do
      has_many :documents, as: :documentable, autosave: true,
                           dependent: :destroy

      accepts_nested_attributes_for :documents, allow_destroy: true

      def new_documents=(val)
        Array(val).each do |document|
          documents.build(document: document)
        end
      end
    end
  end
end

# frozen_string_literal: true

module C
  module NonDeletable
    extend ActiveSupport::Concern

    included do
      has_one :non_delete, as: :non_deletable, dependent: :destroy

      before_create do
        create_non_delete!
      end

      def destroy
        create_non_delete! unless non_delete
        non_delete.update(deleted: true)
      end

      def deleted?
        create_non_delete! unless non_delete
        non_delete.deleted
      end
    end

    def self.included(klass)
      klass.instance_eval do
        default_scope do
          includes(:non_delete)
            .where(c_non_deletes: { deleted: false })
        end
      end
    end
  end
end

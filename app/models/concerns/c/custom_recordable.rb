# frozen_string_literal: true

module C
  module CustomRecordable
    extend ActiveSupport::Concern

    included do
      has_many :custom_values, as: :custom_recordable, dependent: :destroy

      # Getting associated fields for the class
      def has_custom_fields?
        !C::CustomField.all.empty?
      end

      def custom_fields
        C::CustomField.all
      end

      # Returning the value for a field name
      def custom_value_for(query)
        field = C::CustomField.find_by(name: query)
        vals = custom_values.where(custom_field: field)
        if vals.empty?
          nil
        else
          vals.first.value
        end
      end

      # saving custom values
      def custom_values=(val)
        val.values.each do |custom|
          if (custom_value = custom_values
                                 .find_by(
                                   custom_field_id: custom[:custom_field_id],
                                   custom_recordable: self
                                 )
             )
            custom_value.update(value: custom[:custom_value])
          else
            custom_values
              .build(value: custom[:custom_value],
                     custom_field_id: custom[:custom_field_id],
                     custom_recordable: self)
          end
        end
      end
    end

    class_methods do
      CUSTOM_VALUE_ATTRIBUTES = [custom_values: []].freeze
    end
  end
end

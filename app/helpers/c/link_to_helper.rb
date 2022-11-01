# frozen_string_literal: true

# Helper for short hand links rather than always passing through params if very
# common usage

module C
  module LinkToHelper
    def link_to_delete(text, resource, opts={})
      nested = [opts.delete(:nested) { [] }].flatten
      link_to text, [:confirm_destroy, *nested, resource], opts
    end

    def link_to_add_fields(name, f, assoc, opts={})
      new_object = f.object.send(assoc).build
      id = new_object.object_id
      fields = f.fields_for(assoc, new_object, child_index: id) do |builder|
        render assoc.to_s.singularize + '_fields', f: builder
      end
      link_to name, '#', data: { fields: fields.gsub('\n', ''), fields_id: id }.merge(opts)
    end

    def link_to_reserve(text, product)
      link_to(text,
              new_front_end_product_reservation_path(product_id: product.id))
    end
  end
end

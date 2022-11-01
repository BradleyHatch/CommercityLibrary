# frozen_string_literal: true

module C
  class CFormBuilder < ActionView::Helpers::FormBuilder
    def error_messages
      return unless object.respond_to?(:errors) && object.errors.any?

      header = @template.content_tag(:h4, 'Errors prevented the form from saving', class: 'title-error')
      errors_array = object.errors.full_messages.map { |message| @template.content_tag(:li, message) }
      errors_list = @template.safe_join([header, @template.safe_join(errors_array)])

      @template.content_tag(:ul, @template.raw(errors_list), class: 'errors form_errors')
    end

    def price_field(method, name=method.to_s.titleize.to_s, _options={})
      @template.field_set_tag '', class: 'price_field' do
        @template.content_tag(:span, name, class: 'fieldset-title') +
          fields_for(method) do |builder|
            @template.content_tag(:div, class: 'gs') do
              @template.content_tag(:div, class: 'field field--inner-label g-1') { builder.label(:without_tax) + builder.number_field(:without_tax, step: 0.01, min: 0) } +
                @template.content_tag(:div, class: 'field field--inner-label g-1 g-gutter--narrow') { builder.label(:with_tax) + builder.number_field(:with_tax, step: 0.01, min: 0) } +
                @template.content_tag(:div, class: 'field field--inner-label g-1 g-gutter--narrow') { builder.label(:tax_rate) + builder.number_field(:tax_rate, step: 0.01, min: 0) }
            end +
              builder.label(:override) { builder.check_box(:override) + @template.content_tag(:span, 'Override tax rate', class: 'checkbox-span-label') }
          end
      end
    end

    def image_field(method, options = {})
      @template.field_set_tag '', class: 'image_field' do
        @template.content_tag(:span, method.to_s.titleize, class: 'fieldset-title') +
          hidden_field("#{method}_cache") +
          (@template.image_tag(@object.send(method)) || '') +
          file_field(method, options)
      end
    end

    def tiny_mce_text_area(method, tinymce_config='standard')
      text_area(method, class: 'tinymce') +
        @template.send("tinymce_#{tinymce_config}")
    end

  end
end

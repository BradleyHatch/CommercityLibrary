# frozen_string_literal: true

module C
  module SalesHelper
    def inline_invoice_fields(title)
      result = begin
                 yield
               rescue NoMethodError
                 nil
               end
      return unless result
      content_tag :div, class: 'inline_invoice_fields' do
        content_tag(:div, title, class: 'label') +
          content_tag(:div, result, class: 'value')
      end
    end
  end
end

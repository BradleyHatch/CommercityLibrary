# frozen_string_literal: true

module C
  module ApplicationHelper
    include FontAwesome::Rails::IconHelper
    ActionView::Base.default_form_builder = CFormBuilder

    def store_page_title(title)
      title ? "#{title} | #{C.store_name}" : C.store_name
    end

    def index_table(collection, index_data, opts={})
      content_tag :div, class: 'data_table' do
        render 'index_table', collection: collection, index_data: index_data, sortable: opts[:sortable], bulk_actions: opts[:bulk_actions]
      end
    end

    def tinymce_standard
      tinymce(height: 200,
              menubar: false,
              plugins: ['autolink lists link image media charmap anchor',
                        'insertdatetime media table contextmenu paste code textcolor uploadimage colorpicker code'],
              toolbar: 'undo redo styleselect bold italic alignleft aligncenter alignright alignjustify bullist numlist link media uploadimage forecolor fontsizeselect code')
    end

    # Use safe raw to restrict html usage but still render desired html
    def safe_raw(str)
      safe_string = sanitize(str, tags: %w[a b blockquote code del dd dl dt em
                                           h1 h2h3 i img kbd li ol p pre s sup
                                           sub strong strike ul br hr])
      raw(safe_string)
    end

    # Creates a select list which indicates hierachy
    def depth_select_options(record)
      opts = []
      save_pair = proc do |level, i|
        level.each do |key, value|
          next if key.id == record.id
          opts.append(["#{'-' * i}#{key.name}", key.id])
          save_pair.call(value, i + 1) if value.class <= Hash
        end
      end
      save_pair.call(record.class.hash_tree, 0)
      opts
    end
  end
end

module C
  class Template::Group < ApplicationRecord
    include Orderable

    has_many :regions

    validates :name, presence: true

    def displayed_on
      this = []
      DISPLAY_LIST.each do |model_name|
        this << "C::#{model_name}".constantize.where(template_group_id: id).pluck(:name)
      end
      this.any? ? this.join(', ').chomp(', ') : 'Not yet chosen for display on any pages'
    end

    DISPLAY_LIST = ['Content', 'Category']

    INDEX_TABLE = {
      '': {},
      'Name': {
        link: {
          name: { call: 'name' },
          options: '[:edit, object]'
        }
      },
      'Edit': {
        link: {
          name: { text: 'Edit' },
          options: '[:edit, object]'
        }
      },
      'Displayed On': { call: 'displayed_on' }
    }.freeze

  end
end

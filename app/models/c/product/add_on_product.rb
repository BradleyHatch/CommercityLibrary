# frozen_string_literal: true

module C
  module Product
    class AddOnProduct < ApplicationRecord
      belongs_to :main, class_name: 'C::Product::Master',
                        foreign_key: :main_id
      belongs_to :add_on, class_name: 'C::Product::Master',
                          foreign_key: :add_on_id

      validates :main, presence: true
      validates :add_on, presence: true
    end
  end
end

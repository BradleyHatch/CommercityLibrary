module C
  class CollectionCategory < ApplicationRecord
    belongs_to :category, class_name: 'C::Category'
    belongs_to :collection, class_name: 'C::Collection'
  end
end

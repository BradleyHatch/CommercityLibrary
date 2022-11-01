module C
  class GoogleCategory < ApplicationRecord
    acts_as_tree

    validates :name, presence: true
    validates :category_id, presence: true, uniqueness: true
    validates :full_path, presence: true

    def self.create_hierarchy
      find_each do |category|
        next if category.category_parent_name == category.name || category.category_parent_name.blank?
        category.update!(
          parent_id: find_by(name: category.category_parent_name).id
        )
      end
    end
  end
end

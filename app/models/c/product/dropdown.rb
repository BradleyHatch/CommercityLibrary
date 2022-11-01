module C
  class Product::Dropdown < ApplicationRecord

    has_many :dropdown_options
    has_many :dropdown_categories
    has_many :categories, through: :dropdown_categories
    has_many :dropdown_variants
    has_many :variants, through: :dropdown_variants

    validates :name, presence: true

  end
end

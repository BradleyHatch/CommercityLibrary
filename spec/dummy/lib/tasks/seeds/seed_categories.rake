# frozen_string_literal: true

task seed_categories: :environment do
  C::Category.delete_all

  def seed_children(record, max=5)
    max -= rand(1..3)
    return if max <= 0
    max.times do
      c = record.children.create(name: Faker::Commerce.department)
      seed_children(c, max)
    end
  end
  
  5.times do
    c = C::Category.create(name: Faker::Commerce.department)
    seed_children(c)
  end
end

# frozen_string_literal: true

task seed_content: :environment do
  C::Content.basic_page.find_or_create_by!(home: true) do |content|
    content.name = 'Home'
    content.title = 'Home'
    content.body = 'This is the home page'
    content.template = 'home'
    content.slug = 'home'
  end

  C::Content.basic_page.find_or_create_by!(name: 'Blogs') do |content|
    content.template = 'blogs'
    content.body = 'This is the blogs page'
  end
end

class CreateTemplateGroupAndRemoveOldColumns < ActiveRecord::Migration[5.0]

  def up

    add_column :c_template_regions, :group_id, :integer
    C::Template::Region.reset_column_information

    if C::Template::Region.count > 0
      group = C::Template::Group.create!(name: 'Home Group')
      C::Template::Region.update_all(group_id: group.id)

      if (home = C::Content.basic_page.find_by(slug: 'home'))
        home.update(template_group_id: group.id)
      end
    end

    remove_column :c_template_regions, :content_id, :integer

  end

  def down

    add_column :c_template_regions, :content_id, :integer
    C::Template::Region.reset_column_information

    if C::Template::Region.count > 0
      group = C::Template::Group.first

      if (home = C::Content.basic_page.find_by(slug: 'home'))
        group.regions.update_all(content_id: home.id)
      end

    end

    remove_column :c_template_regions, :group_id, :integer

  end

end

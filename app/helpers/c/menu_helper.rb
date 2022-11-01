# frozen_string_literal: true

module C
  module MenuHelper
    def menu(name, depth=2)
      return unless (menu = MenuItem.find_by(name: name))
      menu_list menu.children.hash_tree(limit_depth: depth)
    end

    def menu_list(tree)
      unless tree.empty?
        content_tag(:ul, class: 'menu-list__items') do
          safe_join(tree.map { |root| menu_item root })
        end
      end
    end

    def menu_item(item)
      content_tag :li do
        raw(link_to(item[0].name,
                    menu_item_link(item[0]),
                    class: ('active' if active_menu_item?(item[0]))) +
        menu_list(item[1]))
      end
    end

    def menu_item_link(item)
      item.content ? front_end_content_path(item.content) : item.link
    end

    def active_menu_item?(item)
      item.self_and_descendants.map do |itm|
        menu_item_link(itm)
      end.include?(request.path)
    end

    def category_list(root=C::Category)
      hash = root.is_a?(Hash) ? root : root.hash_tree
      content_tag(:ul, class: 'category-list__items') do
        safe_join(hash.map { |root| category_item root })
      end
    end

    def category_item(item)
      content_tag :li do
        raw(link_to(item[0].name,
                    front_end_category_path(item[0])) + category_list(item[1]))
      end
    end


  end
end

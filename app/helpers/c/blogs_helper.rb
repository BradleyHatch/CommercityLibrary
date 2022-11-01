# frozen_string_literal: true

module C
  module BlogsHelper
    # # Call in the controller to allow usage of blog_archive_menu and blog_archive_month_submenu
    # # Returns the collection of blogs filtered by the params
    # # Optionally accepts a limit for the size of the returned collection
    # def archive_blogs(limit = nil)
    #   @blog_archive_filter_years = []
    #   @blog_archive_filter_months = []
    #
    #   year = params[:year] || Time.now.year
    #   if params[:month].to_i.postive? && params[:month].to_i < 13
    #     month = params[:month]
    #   else
    #     month = Time.now.month
    #     params[:month] = nil
    #   end
    #
    #   if C::Blog.any?
    #     age_limit = C::Blog.order(:created_at).limit(1).first&.created_at&.beginning_of_year
    #     num_years = Time.now.year - age_limit.year
    #     @blog_archive_filter_years = (age_limit.year..(age_limit.year + num_years)).to_a.reverse
    #     @blog_archive_filter_years.select! { |y| C::Blog.created_in_year(year: y).any? }
    #     @blog_archive_filter_months = if age_limit.year.to_s == params[:year].to_s
    #                                     (1..age_limit.month).to_a
    #                                   else
    #                                     (1..12).to_a
    #                                   end
    #     @blog_archive_filter_months.select! { |m| C::Blog.created_in_month(year: year, month: m).any? }
    #     if params[:month]
    #       return C::Blog.created_in_month(month: month, year: year, limit: limit).ordered
    #     else
    #       return C::Blog.created_in_year(year: year, limit: limit).ordered
    #     end
    #   end
    #   nil
    # end
    #
    # # Returns html for a ul of links, which set params[:year]
    # # Only months from @blog_archive_filter_years are listed
    # # Also accepts an options hash
    # # The :permitted option expects an array of keys which are permitted to be included in the generated links
    # # The :submenu option expects a boolean, which can be used to disable rendering the month submenu
    # def blog_archive_menu(options = {})
    #   permitted = options[:permitted] || []
    #   submenu = options[:submenu]
    #   submenu = true if submenu.nil?
    #
    #   content_tag :ul do
    #     result = ''
    #
    #     @blog_archive_filter_years.each do |filter_year|
    #       result += if params[:year].to_s == filter_year.to_s
    #                   if submenu
    #                     if params[:month]
    #                       content_tag :li, (
    #                       (render partial: 'c/front/blogs/archive_filter_year', locals: { permitted: permitted, archive_filter_year: filter_year }) +
    #                           blog_archive_month_submenu(permitted: permitted)
    #                       )
    #                     else
    #                       content_tag :li, (
    #                       raw filter_year.to_s + blog_archive_month_submenu(permitted: permitted)
    #                       )
    #                               end
    #                   else
    #                     content_tag :li, filter_year.to_s
    #                             end
    #                 else
    #                   content_tag :li, (render partial: 'c/front/blogs/archive_filter_year', locals: { permitted: permitted, archive_filter_year: filter_year })
    #                 end
    #     end
    #     raw result
    #   end
    # end
    #
    # # Returns html for a ul of links, which set params[:month]
    # # Only months from @blog_archive_filter_months are listed
    # # Accepts an options hash
    # # The :permitted option expects an array of keys which are permitted to be included in the generated links
    # def blog_archive_month_submenu(options = {})
    #   permitted = options[:permitted] || []
    #   content_tag :ul do
    #     # render partial: 'c/front/blogs/archive_filter_month', collection: @blog_archive_filter_months, locals: {permitted: permitted}
    #     result = ''
    #     @blog_archive_filter_months.each do |filter_month|
    #       result += if params[:month].to_s == filter_month.to_s
    #                   content_tag :li, (Date::MONTHNAMES[filter_month])
    #                 else
    #                   render partial: 'c/front/blogs/archive_filter_month', locals: { permitted: permitted, archive_filter_month: filter_month }
    #                 end
    #     end
    #     raw result
    #   end
    # end
    #
    # # Given a hash, permits only :month and :year
    # # Accepts an options hash
    # # The :permitted option expects an array of other keys to permit
    # def safe_params(unsafe = {}, options = {})
    #   permitted = options[:permitted] || []
    #   permitted.push :month, :year
    #   params.merge(unsafe).merge(only_path: true, script_name: nil).permit(permitted)
    # end
  end
end



# frozen_string_literal: true

# This file just provides aliases for render calls
# Should simplify reorginising of files as can just change references here
module C
  module RenderHelper
    def contact_form
      render('c/front_end/contents/contact_form')
    end

    def reservation_form
      render('c/front_end/product_reservations/form')
    end
  end
end

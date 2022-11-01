class AddContentIdToTestimonials < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_testimonials, :content, index: true
  end
end

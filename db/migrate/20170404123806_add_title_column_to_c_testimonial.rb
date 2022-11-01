class AddTitleColumnToCTestimonial < ActiveRecord::Migration[5.0]
  def change
    add_column :c_testimonials, :title, :string
  end
end

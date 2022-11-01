class Addthreesixtbooltothethingbro < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_variants, :three_sixty_image, :boolean, default: false

  end
end

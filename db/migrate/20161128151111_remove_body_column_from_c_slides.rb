# frozen_string_literal: true
class RemoveBodyColumnFromCSlides < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_slides, :body
  end
end

# frozen_string_literal: true
class CreateCApqsProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :c_apqs_products do |t|
      t.belongs_to :product, index: true
      t.belongs_to :amazon_processing_queue, index: true
    end
  end
end

class CreateCProductAnswers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_answers do |t|
      t.references :question, index: true, foreign_key: { to_table: :c_product_questions }
      t.text :body
      t.boolean :sent, default: false
      t.boolean :external, default: false

      t.timestamps
    end
  end
end

class CreateCProductQuestions < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_questions do |t|
      t.references :variant, index: true, foreign_key: { to_table: :c_product_variants }
      t.string :subject
      t.text :body
      t.integer :source
      t.string :sender_id
      t.string :sender_email
      t.string :message_id, index: true
      t.boolean :answered

      t.timestamps
    end
  end
end

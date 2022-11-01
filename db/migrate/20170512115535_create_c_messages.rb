class CreateCMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_messages do |t|
      t.string :subject
      t.text :body
      t.boolean :read, default: false
      t.boolean :replied, default: false
      t.integer :source
      t.string :sender_id
      t.string :message_id

      t.timestamps
    end
  end
end

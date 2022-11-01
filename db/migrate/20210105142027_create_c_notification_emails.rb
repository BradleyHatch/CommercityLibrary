class CreateCNotificationEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :c_notification_emails do |t|
      t.string :email, null: false, default: ''

      t.boolean :orders, default: false
      t.boolean :enquiries, default: false

      t.timestamps
    end
  end
end

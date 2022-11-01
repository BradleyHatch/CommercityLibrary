class CreateCNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :c_notifications do |t|
      t.references :notifiable, :polymorphic => true
      t.boolean :read, default: false

      t.timestamps
    end
  end
end

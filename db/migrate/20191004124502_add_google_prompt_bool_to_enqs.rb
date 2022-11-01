class AddGooglePromptBoolToEnqs < ActiveRecord::Migration[5.0]
  def change
    add_column :c_enquiries, :google_prompt, :boolean, default: false
  end
end

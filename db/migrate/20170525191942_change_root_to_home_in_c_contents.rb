class ChangeRootToHomeInCContents < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_contents, :root, :home
  end
end

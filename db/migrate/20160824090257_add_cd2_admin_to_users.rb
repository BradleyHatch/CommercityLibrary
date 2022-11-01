# frozen_string_literal: true
class AddCd2AdminToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_users, :cd2admin, :boolean, default: false
  end
end

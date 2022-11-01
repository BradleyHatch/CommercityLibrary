# frozen_string_literal: true

module C
  class Role < ApplicationRecord
    has_many :permissions
    accepts_nested_attributes_for :permissions

    has_many :user_roles
    has_many :users, through: :user_roles

    validates :name, presence: true

    def build_or_find_permissions
      PermissionSubject.find_each do |subject|
        permissions.collect(&:permission_subject_id).include?(subject.id) ||
          permissions.build(permission_subject: subject)
      end
    end
  end
end

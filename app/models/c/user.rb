# frozen_string_literal: true

module C
  class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable, :registerable
    devise :database_authenticatable, :recoverable,
           :rememberable, :trackable, :validatable

    scope :ordered, -> { order name: :asc }

    has_many :user_roles
    has_many :roles, through: :user_roles
    has_many :permissions, -> { distinct }, through: :roles

    validates :name, presence: true

    INDEX_TABLE = {
      'Name': {
        link: {
          name: {
            call: 'name'
          },
          options: '[:edit, object]'
        },
        sort: 'name'
      },
      'Email': {
        call: 'email', sort: 'email'
      },
      'Last Sign In': {
        call: 'last_sign_in_at'
      },
      'Edit': {
        link: {
          name: {
            text: 'edit'
          }, options: '[:edit, object]'
        }
      }
    }.freeze
  end
end

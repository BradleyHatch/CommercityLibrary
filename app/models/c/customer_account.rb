# frozen_string_literal: true

module C
  class CustomerAccount < ApplicationRecord

    enum account_type: C.customer_account_types
    enum payment_type: %i[normal credit]

    has_one :customer, dependent: :destroy

    accepts_nested_attributes_for :customer

    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable

    validates :email, presence: true,
                      uniqueness: {
                        message: 'is already associated with an account.
                                  <a href="/account/sign_in">Click here to sign in</a>.<br>
                                  Not sure what your password is? <a href="/account/password/new">
                                  Click here to reset it now</a>.'
                      },
                      format: { with: /\A[^@\s]+@[^@\s]+\z/ }

    def customer
      super || unless new_record?
                 C::Customer.create!(
                   customer_account_id: id,
                   name: email,
                   email: email,
                 )
               end
    end
  end
end

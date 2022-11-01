# frozen_string_literal: true

module C
  class Customer < ApplicationRecord
    include ChannelEnum
    include CustomRecordable

    ransacker :name_case_insensitive, type: :string do
      arel_table[:name].lower
    end

    belongs_to :account, class_name: 'C::CustomerAccount', foreign_key: 'customer_account_id'
    has_many :addresses, dependent: :nullify
    has_many :orders, class_name: 'C::Order::Sale', dependent: :nullify
    has_many :wishlist_items, dependent: :destroy
    has_one :cart, dependent: :nullify

    accepts_nested_attributes_for :account

    mount_uploader :thumbnail, ImageUploader

    scope :alphabetical, -> { order(name: :asc) }
    scope :companies, -> { where.not(company: nil) }

    # validations
    validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: 'is not a valid email address' }

    validates :name, presence: true

    # Amazon email should only set from an auto-generated amazon account
    validates :amazon_email, uniqueness: true,
                             allow_blank: true,
                             format: {
                               with: /\A[^@\s]+@[^@\s]+\z/,
                               message: 'is not a valid email address'
                             }

    def store_cart(cart)
      cart.customer_id = id
      cart.save!
    end

    def assign_cart(cart_id)
      cart = C::Cart.find(cart_id)
      cart.update(customer_id: id)
      cart.order.update(customer: self) if cart.order.present?
    rescue ActiveRecord::RecordNotFound
      logger.warn 'Manual 404 raised'
    end

    def wishlist
      wishlist_items
    end

    def is_trade?
      false
    end

    INDEX_TABLE = {
      '_thumbnail': { image: 'thumbnail' },
      'Customer': { link: { name: { call: 'name' }, options: '[:edit, object]' }, sort: 'name_case_insensitive' },
      'Email': { call: 'email', sort: 'email' },
      'Company': { call: 'company', sort: 'company' },
      'Edit': { link: { name: { text: 'edit' }, options: '[:edit, object]' } }
    }.freeze

    BULK_ACTIONS = [
      ['Delete', :destroy]
    ].freeze
  end
end

# frozen_string_literal: true

module C
  class Setting < ApplicationRecord
    belongs_to :data, polymorphic: true, autosave: true, dependent: :destroy
    belongs_to :group, class_name: 'C::SettingGroup',
                       foreign_key: :setting_group_id

    validates :data, presence: true
    validates :key, presence: true, uniqueness: true
    validates :value, presence: true,
                      if: proc { |s| s.data.present? && s.type != :boolean }

    delegate :value, :value=, to: :data

    # delegate any method calls to the data models (setting types)
    def method_missing(name, *args)
      if data.respond_to? name
        data.send(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      super
    end

    def self.new_setting(key, *args)
      opts = args.extract_options!
      data = create_setting_from_model(opts, args)
      setting_group(opts).create!(key: key, data: data)
    end

    def self.setting_type_model(type)
      case type
      when :image
        SettingType::Image
      when :text
        SettingType::Text
      when :boolean
        SettingType::Boolean
      else
        SettingType::String
      end
    end

    def self.create_setting_from_model(opts, args)
      value = opts.fetch(:value, args[0])
      setting_type_model(opts.delete(:type)).new(
        value: value,
        default: opts.fetch(:default, value || args[0])
      )
    end

    def self.setting_group(opts)
      SettingGroup.find_by(
        machine_name: opts.fetch(:group, :default).to_s.parameterize
      )&.settings || Setting
    end

    def self.get(key)
      setting = find_by(key: key)
      begin
        raise KeyNotFound, key unless setting
        setting.data.value
      rescue C::Setting::KeyNotFound
        false
      end
    end

    def self.set(key, value)
      setting = find_by(key: key)
      raise KeyNotFound, key unless setting
      setting.data.update(value: value)
    end

    class KeyNotFound < StandardError
      def initialise(key)
        super "#{key} not found"
      end
    end

    INDEX_TABLE = {
      'Key': { primary: 'key' },
      'Value': { call: 'data.value' }
    }.freeze
  end
end

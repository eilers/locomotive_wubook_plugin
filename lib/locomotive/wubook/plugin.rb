
require 'rubygems'
require 'bundler/setup'
require 'date'

require 'wired'
require 'locomotive_plugins'

require_relative 'plugin/available_days_tag'
require_relative 'plugin/check_interval_tag'
require_relative 'plugin/set_as_booked_tag'
require_relative 'plugin/prices_tag'

module Locomotive
  module WuBook
    class Plugin
      include Locomotive::Plugin

      def self.default_plugin_id
        'wubook'
      end

      def initialize

      end

      def config_template_file
        File.join(File.dirname(__FILE__), 'plugin', 'config.haml')
      end

      def self.liquid_tags
        { 
          :available => AvailableDaysTag,
          :checkInterval => CheckIntervalTag,
          :setAsBooked => SetAsBookedTag,
          :prices => PricesTag
         }
      end

      protected

    end
  end
end

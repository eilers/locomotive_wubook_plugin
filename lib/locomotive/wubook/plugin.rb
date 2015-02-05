
require 'rubygems'
require 'bundler/setup'
require 'date'

require 'wired'
require 'locomotive_plugins'
require_relative 'plugin/plugin_helper'

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
          :available => AvailableDaysBlock,
          :checkInterval => CheckInterval,
          :setAsBooked => SetAsBooked
         }
      end

      protected

    end

    class AvailableDaysBlock < ::Liquid::Tag
      include PluginHelper
      def initialize(tag_name, markup, tokens, context)
        @options = {
          room_ident: ''
        }

        markup.scan(::Liquid::TagAttributes) { |key, value| @options[key.to_sym] = value.gsub(/"|'/, '') }
        super
      end

      def render(context)
        @plugin_obj = context.registers[:plugin_object]
        config = @plugin_obj.config

        returned_string = "["

        # Evaluate variables and use the return of the evaluation if it exists..
        raise "Missing parameter 'room_ident'" if @options[:room_ident].empty?
        room_ident_evaluated = context[@options[:room_ident]]
        @options[:room_ident] = room_ident_evaluated unless room_ident_evaluated.nil? || room_ident_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock room_ident: #{@options[:room_ident]}"

        today = Date.today
        last_day = today.next_month(config['months_ahead'].to_i)

        wired = Wired.new(config)
        wired.aquire_token

        room_data = request_room_data(wired, config['lcode'], @options[:room_ident], today, last_day)

        # Create one entry for each day from now to then.. put a 1 if the day is available or 0 if not.
        (today .. last_day).each_with_index do |date, i|
          returned_string += "," if i > 0

          if room_data[i] != nil && room_data[i]['avail'] === 1 
          then
            returned_string += "1"
          else
            returned_string += "0"  
          end
        end

        wired.release_token

        returned_string + "]"
      end

      def render_disabled(context)
        "Locomotive_wubook_plugin is disabled!"
      end
    end

    class CheckInterval < ::Liquid::Tag
      include PluginHelper
      def initialize(tag_name, markup, tokens, context)
        @options = {
          room_ident: '',
          date_start: '',
          date_end: ''
        }

        markup.scan(::Liquid::TagAttributes) { |key, value| @options[key.to_sym] = value.gsub(/"|'/, '') }
        super
      end

      def render(context)
        @plugin_obj = context.registers[:plugin_object]
        config = @plugin_obj.config

        # Evaluate variables and use the return of the evaluation if it exists..
        raise "Missing parameter 'room_ident'" if @options[:room_ident].empty?
        room_ident_evaluated = context[@options[:room_ident]]
        @options[:room_ident] = room_ident_evaluated unless room_ident_evaluated.nil? || room_ident_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock room_ident: #{@options[:room_ident]}"

        raise "Missing parameter 'date_start'" if @options[:date_start].empty?
        date_start_evaluated = context[@options[:date_start]]
        @options[:date_start] = date_start_evaluated unless date_start_evaluated.nil? || date_start_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock date_start_evaluated: #{@options[:date_start_evaluated]}"

        raise "Missing parameter 'date_end'" if @options[:date_end].empty?
        date_end_evaluated = context[@options[:date_end]]
        @options[:date_end] = date_end_evaluated unless date_end_evaluated.nil? || date_end_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock date_end: #{@options[:date_end]}"

        start_day = Date.strptime(@options[:date_start], '%d.%m.%Y')
        last_day  = Date.strptime(@options[:date_end], '%d.%m.%Y')
        ::Locomotive.log "**> CheckInterval: Date Interval: #{start_day} - #{last_day}"

        wired = Wired.new(config)
        wired.aquire_token
        room_data = request_room_data(wired, config['lcode'], @options[:room_ident], start_day, last_day)
        wired.release_token

        # Check whether first day is available. If this is _not_ the case we have to add one day (vacation == departure is allowed)
        is_first_available = room_data[0]['avail'] === 1

        # Check wheter the last day is not available. If this is _not_ the case we have to reduce one day (vacation == departure is allowed)
        is_last_available = room_data[last_day.mjd - start_day.mjd]['avail'] === 1

        # Remove the first or last day from the array.
        room_data.shift  unless is_first_available # Remove first element
        room_data[0..-1] unless is_last_available  # Remove last element

        # Now check the (modified) interval regarding availability
        is_available = true
        room_data.each do |data|
          ::Locomotive.log "**> CheckInterval: check: #{data}"
          if data['avail'] === 0 then
            is_available = false;
            break
          end
        end

        is_available ? "Ok" : "Err"
      end

      def render_disabled(context)
        "Locomotive_wubook_plugin is disabled!"
      end
    end

    # This tag sets the availability of the given days to 0 (false)
    class SetAsBooked < ::Liquid::Tag
      include PluginHelper
      def initialize(tag_name, markup, tokens, context)
        @options = {
          room_ident: '',
          date_start: '',
          date_end: ''
        }

        markup.scan(::Liquid::TagAttributes) { |key, value| @options[key.to_sym] = value.gsub(/"|'/, '') }
        super
      end

      def render(context)
        @plugin_obj = context.registers[:plugin_object]
        config = @plugin_obj.config

        raise "Missing parameter 'room_ident'" if @options[:room_ident].empty?
        room_ident_evaluated = context[@options[:room_ident]]
        @options[:room_ident] = room_ident_evaluated unless room_ident_evaluated.nil? || room_ident_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock room_ident: #{@options[:room_ident]}"

        raise "Missing parameter 'date_start'" if @options[:date_start].empty?
        date_start_evaluated = context[@options[:date_start]]
        @options[:date_start] = date_start_evaluated unless date_start_evaluated.nil? || date_start_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock date_start_evaluated: #{@options[:date_start_evaluated]}"

        raise "Missing parameter 'date_end'" if @options[:date_end].empty?
        date_end_evaluated = context[@options[:date_end]]
        @options[:date_end] = date_end_evaluated unless date_end_evaluated.nil? || date_end_evaluated.empty?
        ::Locomotive.log "**> AvailableDaysBlock date_end: #{@options[:date_end]}"

        start_day = Date.strptime(@options[:date_start], '%d.%m.%Y')
        last_day  = Date.strptime(@options[:date_end], '%d.%m.%Y')
        ::Locomotive.log "**> SetAsBooked: Date Interval: #{start_day} - #{last_day}"

        wired = Wired.new(config)
        wired.aquire_token
        room_id = fetch_room_id(wired, config['lcode'], @options[:room_ident])

        # Set availability for given date interval to 0
        days = []
        (start_day .. last_day).each do |date|
          # Ignore date.. I will just iterate over every day..
          days.push({ 'avail' => 0 })
        end
        avail_data = [ {'id' => room_id, 'days' => days} ]
        ::Locomotive.log "**> SetAsBooked: Set avail to 0 for: #{start_day}: #{avail_data}"
        wired.update_rooms_values(config['lcode'], start_day, avail_data)

        wired.release_token

        # Return a html comment that shows us that everything is fine.
        "<!-- Availability was set to 0 for room #{@options[:room_ident]} from #{@options[:date_start]} to #{@options[:date_end]} -->"
      end

      def render_disabled(context)
        "Locomotive_wubook_plugin is disabled!"
      end
    end
  end
end

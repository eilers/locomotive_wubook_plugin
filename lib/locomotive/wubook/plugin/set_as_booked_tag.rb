require 'date'

require 'wired'
require 'locomotive_plugins'
require_relative 'plugin_helper'

module Locomotive
  module WuBook
    # This tag sets the availability of the given days to 0 (false)
    class SetAsBookedTag < ::Liquid::Tag
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
        ::Locomotive.log "**> SetAsBookedTag room_ident: #{@options[:room_ident]}"

        raise "Missing parameter 'date_start'" if @options[:date_start].empty?
        date_start_evaluated = context[@options[:date_start]]
        @options[:date_start] = date_start_evaluated unless date_start_evaluated.nil?
        ::Locomotive.log "**> SetAsBookedTag date_start_evaluated: #{@options[:date_start_evaluated]}"

        raise "Missing parameter 'date_end'" if @options[:date_end].empty?
        date_end_evaluated = context[@options[:date_end]]
        @options[:date_end] = date_end_evaluated unless date_end_evaluated.nil?
        ::Locomotive.log "**> SetAsBookedTag date_end: #{@options[:date_end]}"

        start_day = @options[:date_start]
        last_day  = @options[:date_end]
        ::Locomotive.log "**> SetAsBookedTag: Date Interval: #{start_day} - #{last_day}"

        # Last day is the day of departure. It will not be marked as booked
        last_day -= 1
        ::Locomotive.log "**> Effective end-day: #{last_day} "

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
        ::Locomotive.log "**> SetAsBookedTag: Set avail to 0 for: #{start_day}: #{avail_data}"
        wired.update_rooms_values(config['lcode'], start_day, avail_data)

        wired.release_token

        # Return a html comment that shows us that everything is fine.
        "<!-- Availability was set to 0 for room #{@options[:room_ident]} from #{@options[:date_start]} to #{@options[:date_end]} -->"
      end

      def render_disabled(context)
        "<!-- Locomotive_wubook_plugin is disabled! -->"
      end
    end
  end
end


require 'date'

require 'wired'
require 'locomotive_plugins'
require_relative 'plugin_helper'

module Locomotive
  module WuBook
    class CheckIntervalTag < ::Liquid::Tag
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
        ::Locomotive.log "**> CheckIntervalTag room_ident: #{@options[:room_ident]}"

        raise "Missing parameter 'date_start'" if @options[:date_start].empty?
        date_start_evaluated = context[@options[:date_start]]
        @options[:date_start] = date_start_evaluated unless date_start_evaluated.nil?
        ::Locomotive.log "**> CheckIntervalTag date_start_evaluated: #{@options[:date_start]}"

        raise "Missing parameter 'date_end'" if @options[:date_end].empty?
        date_end_evaluated = context[@options[:date_end]]
        @options[:date_end] = date_end_evaluated unless date_end_evaluated.nil?
        ::Locomotive.log "**> CheckIntervalTag date_end: #{@options[:date_end]}"

        start_day = @options[:date_start]
        last_day  = @options[:date_end]
        ::Locomotive.log "**> CheckIntervalTag: Date Interval: #{start_day} - #{last_day}"

        # Last day is the day of departure. It will not be marked/handled as booked
        last_day -= 1
        ::Locomotive.log "**> Effective end-day: #{last_day} "

        wired = Wired.new(config)
        wired.aquire_token
        room_data = request_room_data(wired, config['lcode'], @options[:room_ident], start_day, last_day)
        wired.release_token

        # Now check the (modified) interval regarding availability
        is_available = true
        room_data.each do |data|
          ::Locomotive.log "**> CheckIntervalTag: check: #{data}"
          if data['avail'] === 0 then
            is_available = false;
            break
          end
        end

        is_available ? "Ok" : "Err"
      end

      def render_disabled(context)
        "Ok"
      end
    end
  end
end


require 'date'

require 'wired'
require 'locomotive_plugins'
require_relative 'plugin_helper'

module Locomotive
  module WuBook
    class AvailableDaysTag < ::Liquid::Tag
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
        ::Locomotive.log "**> AvailableDaysTag room_ident: #{@options[:room_ident]}"

        today = Date.today
        last_day = today.next_month(config['months_ahead'].to_i)

        wired = Wired.new(config)
        wired.aquire_token

        room_data = request_room_data(wired, config['lcode'], @options[:room_ident], today, last_day)

        # Create one entry for each day from now to then.. put a 1 if the day is available or 0 if not.
        (today .. last_day).each_with_index do |date, i|
          returned_string += "," if i > 0

          if room_data[i] != nil && room_data[i]['avail'] >= 1 
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
        "[]"
      end
    end
  end
end

require 'date'

require 'wired'
require 'locomotive_plugins'
require_relative 'plugin_helper'

module Locomotive
  module WuBook
    class PricesTag < ::Liquid::Tag
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
        unless room_ident_evaluated.nil? || room_ident_evaluated.empty? then
          @options[:room_ident] = room_ident_evaluated
        else
          return "[]"
        end

        ::Locomotive.log "**> AvailableDaysTag room_ident: #{@options[:room_ident]}"

        today = Date.today
        last_day = today.next_month(config['months_ahead'].to_i)

        wired = Wired.new(config)
        wired.aquire_token

        base_room_data = fetch_room_base_data(wired, config['lcode'], @options[:room_ident])
        base_price = base_room_data[0]["price"]

        room_data = Rails.cache.fetch(config['lcode'] + @options[:room_ident] + today.to_s + last_day.to_s + "/room_data", expires_in: 1.hours) do 
          ::Locomotive.log "**> Cache fetch for key: #{config['lcode'] + @options[:room_ident] + today.to_s + last_day.to_s + "/room_data"}"
          request_room_data(wired, config['lcode'], @options[:room_ident], today, last_day)
        end

        # Create one entry for each day from now to then.. put a 1 if the day is available or 0 if not.
        (today .. last_day).each_with_index do |date, i|
          returned_string += "," if i > 0

          if room_data[i] != nil && room_data[i].has_key?("price")
          then
            returned_string += room_data[i]["price"].to_s
          else
            returned_string += base_price.to_s  
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

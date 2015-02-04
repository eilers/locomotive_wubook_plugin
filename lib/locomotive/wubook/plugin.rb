
require 'rubygems'
require 'bundler/setup'
require 'date'

require 'wired'
require 'locomotive_plugins'

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
        { :available => AvailableDaysBlock }
      end

      protected

    end

    class AvailableDaysBlock < ::Liquid::Tag
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

        raise "Missing parameter 'room_ident'" if @options[:room_ident].empty?

        # Fetch availability data for given room identifier
        # As the room id is not visible in the web interface, we have to find it first. We use the short name as identifier.
        wired = Wired.new(config)
        wired.aquire_token

        # Start with finding the room-id for the room with a special name
        rooms = wired.fetch_rooms(config['lcode'])
        filtered_rooms = rooms.select { |room_hash| room_hash['shortname'].casecmp @options['room_ident'.to_sym] }
        raise "Unable to find a room with identifier: #{@options['room_ident']}" if filtered_rooms.length == 0
        room_identifier = filtered_rooms[0]['id']
        raise "Unable to get the room id." if room_identifier == nil

        # Now we will request the room values. Start will be today with data for the next 2 years
        today = Date.today
        last_day = today.next_month(config['months_ahead'].to_i)
        room_values = wired.fetch_rooms_values(config['lcode'], today, last_day, [room_identifier])
        room_data = room_values[room_identifier.to_s]
        raise "Missing room data from server." if room_data == nil

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
    end
  end
end

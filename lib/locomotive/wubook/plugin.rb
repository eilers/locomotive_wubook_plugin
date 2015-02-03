
require 'rubygems'
require 'bundler/setup'
require 'xmlrpc/client'
require 'date'

require 'locomotive_plugins'

class XMLRPC::Client
  def set_debug
    @http.set_debug_output($stderr);
  end
end

module Locomotive
  module WuBook

    # Implementation of the WuBook API. 
    # The Documentation can be found here: https://sites.google.com/site/wubookdocs/wired/wired-pms-xml
    class Wired
      def initialize(config)
        # The config will contain the following keys: account_code, password, provider_key
        @config = config
      end
      
      def config
        @config
      end

      # Requests a token from the server. 
      # The token is stored in this object and will be used automatically.
      def aquire_token
        token_data = server.call("acquire_token", @config['account_code'], @config['password'], @config['provider_key'])
        status = token_data[0]
        @token = token_data[1]
        if (is_error(status)) 
          error_message = decode_error(status)
          raise "Unable to aquire token. Reason: #{error_message}, Message: #{data}"
        end
        @token
      end

      def is_token_valid(token = @token)
        response = server.call("is_token_valid", token)
        status = response[0]
        status == 0
      end

      # Releases the token fetched by #aquire_token
      def release_token(token = @token)
        response = server.call("release_token", token)

        handle_response(response, "Unable to release token")
        @token = nil
      end

      # Fetch rooms
      def fetch_rooms(lcode, token = @token)
        response = server.call("fetch_rooms", token, lcode)

        handle_response(response, "Unable to fetch room data")
      end

      # Update room values
      # ==== Attributes
      # * +dfrom+ - A Ruby date object (start date)
      # * +rooms+ - A hash with the following structure: [{'id' => room_id, 'days' => [{'avail' => 0}, {'avail' => 1}]}]
      def update_rooms_values(lcode, dfrom, rooms, token = @token)
        response = server.call("update_rooms_values", token, lcode, dfrom.strftime('%d/%m/%Y'), rooms)

        handle_response(response, "Unable to update room data")
      end

      # Request data about rooms.
      # ==== Attributes
      # * +dfrom+ - A Ruby date object (start date)
      # * +dto+ - A Ruby date object (end date)
      # * +rooms+ - An array containing the requested room ids
      def fetch_rooms_values(lcode, dfrom, dto, rooms = nil, token = @token)
        if rooms != nil then
          response = server.call("fetch_rooms_values", token, lcode, dfrom.strftime('%d/%m/%Y'), dto.strftime('%d/%m/%Y'), rooms)
        else
          response = server.call("fetch_rooms_values", token, lcode, dfrom.strftime('%d/%m/%Y'), dto.strftime('%d/%m/%Y'))
        end

        handle_response(response, "Unable to fetch room values")
      end

      protected

      def handle_response(response, message)
        status = response[0]
        data   = response[1]
        if (is_error(status)) 
          error_message = decode_error(status)
          raise "#{message}. Reason: #{error_message}, Message: #{data}"
        end
        data
      end

      def decode_error(code)
        codes = {
         0    => 'Ok',
         -1    => 'Authentication Failed',
         -2    => 'Invalid Token',
         -3    => 'Server is busy: releasing tokens is now blocked. Please, retry again later',
         -4    => 'Token Request: requesting frequence too high',
         -5    => 'Token Expired',
         -6    => 'Lodging is not active',
         -7    => 'Internal Error',
         -8    => 'Token used too many times: please, create a new token',
         -9    => 'Invalid Rooms for the selected facility',
         -10   => 'Invalid lcode',
         -11   => 'Shortname has to be unique. This shortname is already used',
         -12   => 'Room Not Deleted: Special Offer Involved',
         -13   => 'Wrong call: pass the correct arguments, please',
         -14   => 'Please, pass the same number of days for each room',
         -15   => 'This plan is actually in use',
         -100  => 'Invalid Input',
         -101  => 'Malformed dates or restrictions unrespected',
         -1000 => 'Invalid Lodging/Portal code',
         -1001 => 'Invalid Dates',
         -1002 => 'Booking not Initialized: use facility_request()',
         -1003 => 'Objects not Available',
         -1004 => 'Invalid Customer Data',
         -1005 => 'Invalid Credit Card Data or Credit Card Rejected',
         -1006 => 'Invalid Iata',
         -1007 => 'No room was requested: use rooms_request()' 
        }
        codes[code]
      end

      def server
        server = XMLRPC::Client.new2 ("https://wubook.net/xrws/")
        #server.set_debug
        server
      end


      def is_error(code)
        code.to_i < 0
      end
    end

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
        room_values = wired.fetch_rooms_values(config['lcode'], Date.today, Date.today.next_month(config['months_ahead'].to_i), [room_identifier])
        room_data = room_values[room_identifier.to_s]
        raise "Missing room data from server." if room_data == nil

        # Create one entry for each day from now to then.. put a 1 if the day is available or 0 if not.
        (Date.today .. Date.today.next_month(config['months_ahead'].to_i * 12)).each_with_index do |date, i|
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

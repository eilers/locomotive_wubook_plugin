
require 'rubygems'
require 'bundler/setup'
require 'xmlrpc/client'

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
      # * +rooms+ - A hash with the following structure: [{'id' >= room_id}]
      def fetch_room_values(lcode, dfrom, dto, rooms = nil, token = @token)
        if rooms != nil then
          response = server.call("fetch_rooms_values", token, lcode, dfrom.strftime('%d/%m/%Y'), dto.strftime('%d/%m/%Y'), rooms)
        else
          response = server.call("fetch_rooms_values", token, lcode, dfrom.strftime('%d/%m/%Y'), dto.strftime('%d/%m/%Y'))
        end
        
        handle_response(response, "Unable to fetch room values")
      end

      protected

      def handle_response(response, error_message)
        status = response[0]
        data   = response[1]
        if (is_error(status)) 
          error_message = decode_error(status)
          raise "#{error_message}. Reason: #{error_message}, Message: #{data}"
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

      before_page_render :authenticate_if_needed

      def self.default_plugin_id
        'wubook'
      end

      def config_template_file
        File.join(File.dirname(__FILE__), 'plugin', 'config.haml')
      end

      protected

    end

  end
end

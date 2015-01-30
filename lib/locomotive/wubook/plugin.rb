
require 'rubygems'
require 'bundler/setup'
require 'xmlrpc/client'

require 'locomotive_plugins'

# This is a quick-and-dirty basic authentication plugin. The login string and
# password are stored in plaintext in the config hash, so it is not secure. The
# configuration also takes a regular expression which specifies the page
# fullpaths which require basic authentication
module Locomotive
  module WuBook
    class Wired
      def initialize(config)
        # The config will contain the following keys: account_code, password, provider_key
        @config = config
      end
      
      def config
        @config
      end

      def aquire_token
        token_data = server.call("acquire_token", @config['account_code'], @config['password'], @config['provider_key'])
        status = token_data[0]
        data   = token_data[1]
        if (is_error(status)) 
          error_message = decode_error(status)
          raise "Unable to aquire token. Reason: #{error_message}, Message: #{data}"
        end
        data
      end

      def is_token_valid(token)
        response = server.call("is_token_valid", token)
        status = response[0]
        status == 0
      end

      def release_token(token)
        response = server.call("release_token", token)
        status = response[0]
        if (is_error(status)) 
          error_message = decode_error(status)
          data   = response[1]
          raise "Unable to release token. Reason: #{error_message}, Message: #{data}"
        end
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

      protected

      def server
        XMLRPC::Client.new2("https://wubook.net/xrws/")
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

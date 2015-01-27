# Basic Auth Plugin
This is a plugin for LocomotiveCMS. It was created to manipulate bookings for booking.com and other channels via WuBook.net.

##  Installation
To install the plugin in LocomotiveCMS, simply [create a LocomotiveCMS
app](http://doc.locomotivecms.com/guides/get-started/install-engine), ensuring
you have all of the [Requirements](http://doc.locomotivecms.com/guides/get-started/requirements) installed, and add your
plugin gem to the app's Gemfile in the `locomotive_plugins` group:

    group(:locomotive_plugins) do
      gem 'wubook_plugin'
      gem 'another_plugin'
    end

## Usage

### Configuring Plugin

This plugin provides a configuration menu to setup the api connection. The following are the avaiable options:

* Account Code - The name of your account
* Password - The password that belongs to the account.
* Provider Key - The key provided to you by WuBook which grants API access

### Liquid Drops

No liquid drops are provided

### Liquid Tags

No liquid tags are provided

### Liquid Filters

No liquid filters are provided

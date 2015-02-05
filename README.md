# WuBook Plugin for Locomotive
This is a plugin for LocomotiveCMS. It was created to manipulate bookings for booking.com and other channels via WuBook.net.
As WuBook suggested not to modify bookings, but to change the availibility of rooms, this plugin only supports the latter one.

## Important
Please note that you need Locomotivecms with the plugin interface provided by Colibri-Software (see https://github.com/colibri-software/locomotive_engine branch: plugin). 
A more recent version can be found here: https://github.com/eilers/locomotive_engine


##  Installation
To install the plugin in LocomotiveCMS, simply [create a LocomotiveCMS
app](http://doc.locomotivecms.com/guides/get-started/install-engine), ensuring
you have all of the [Requirements](http://doc.locomotivecms.com/guides/get-started/requirements) installed, and add your
plugin gem to the app's Gemfile in the `locomotive_plugins` group:

     group(:locomotive_plugins) do
      gem 'locomotive_wubook_plugin'
      gem 'another_plugin'
    end

## Usage

### Configuring Plugin

This plugin provides a configuration menu to setup the api connection. The following are the available options:

* Account Code - The name of your account
* Password - The password that belongs to the account.
* Provider Key - The key provided to you by WuBook which grants API access. You can request this key from devel@wubook.net
* Property Identifier (aka lcode) - You can find property code on your WuBook Website. Please note that only one Property per Plugin is right now supported.
* Booking months ahead: This defines the time frame for possible bookings. Don't use too big numbers, because this will blow up the size of API communication.

### Liquid Drops

No liquid drops are provided

### Liquid Tags

There are three tags implemented:
#### wubook_available
Returns a JSON array that contains one entry for each day of the time interval defined with "Booking months ahead", starting with today. 1 means that the room is available for this day. 0 means: Not available.
    - room_ident: The short name of the room as defined in WuBook

Example:

  	{% wubook_available room_ident: 'TestRoom' %};
Returns
    
    [1,0,0,1]

Which means: Available today, not for today + 1 and not for today + 2 ..
####wubook_setAsBooked
Set a given date range as not available (booked). *Note:*  We will not do any booking here. We will only set the availability of the given room to 0.
    - room_ident: The short name of the room as defined in WuBook
    - date_start: The day of arrival.
    - date_end: The day of departure.

Example:
    
    {% wubook_setAsBooked room_ident:lastBuchung.wubook_room_id date_start: lastBuchung.anreise date_end: lastBuchung.abreise %}

####wubook_checkInterval
Checks whether the given interval is available. *Note:* this tag accepts overlapping arrival and departure days.

Example:
   
	{% wubook_checkInterval room_ident:lastBuchung.wubook_room_id date_start: lastBuchung.anreise date_end: lastBuchung.abreise %}
Returns:
    
	"Ok" 
    
if the booking time frame is available.

### Liquid Filters

No liquid filters are provided

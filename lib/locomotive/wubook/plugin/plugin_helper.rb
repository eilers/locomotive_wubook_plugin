require 'wired'

module PluginHelper
        def fetch_room_id(wired, lcode, room_id)
                # Start with finding the room-id for the room with a special name
                rooms = wired.fetch_rooms(lcode)
                filtered_rooms = rooms.select { |room_hash| room_hash['shortname'].casecmp room_id }
                ::Locomotive.log "**> Filtered rooms #{filtered_rooms} "
                raise "Unable to find a room with identifier: #{room_id}" if filtered_rooms.length == 0
                room_identifier = filtered_rooms[0]['id']
                raise "Unable to get the room id." if room_identifier == nil

                room_identifier
        end

        def request_room_data(wired, lcode, room_id, startDate, endDate)
                # Fetch availability data for given room identifier
                room_identifier = fetch_room_id(wired, lcode, room_id)
                # As the room id is not visible in the web interface, we have to find it first. We use the short name as identifier.
                ::Locomotive.log "**> room_ident #{room_id}"

                # Now we will request the room values. Start will be startDate with data for the next 2 years
                room_values = wired.fetch_rooms_values(lcode, startDate, endDate, [room_identifier])
                room_data = room_values[room_identifier.to_s]
                raise "Missing room data from server." if room_data == nil

                room_data
        end
end
require 'spec_helper'

module Locomotive
  module WuBook
    describe Wired do
      let(:config) { Hash.new }

      let(:wired) { Wired.new({ 'account_code' => 'SE016', 'password' => '59595', 'provider_key' => 'stfeltt39qt777'}) }

      before(:each) do
      end

      it 'should return a valid (mocked) config' do
        expect(wired.config).not_to be_nil
        expect(wired.config).to have_key('account_code')
        expect(wired.config).to have_key('password')
        expect(wired.config).to have_key('provider_key')
      end

      it 'should aquire a token, validate it and return it afterwards' do
        token = wired.aquire_token
        expect(token).not_to be_nil

        expect(wired.is_token_valid).to be_truthy

        wired.release_token

        expect(wired.is_token_valid(token)).to be_falsey
      end

      it 'returns a list of rooms' do
        token = wired.aquire_token
        rooms = wired.fetch_rooms("1422356463", token)
        expect(rooms).not_to be_nil

        wired.release_token
      end

      it 'changes availability of the first room' do
        wired.aquire_token

        # First get the room id
        room = wired.fetch_rooms("1422356463")
        room_id = room[0]['id']

        expect(room_id).not_to be_nil

        # Set next day as not available.
        test_data = [ {'id' => room_id, 'days' => [{'avail' => 0}, {'avail' => 1}]} ]
        wired.update_rooms_values("1422356463", Date.tomorrow, test_data)

        # Check whether change worked. 
        room_values = wired.fetch_rooms_values("1422356463", Date.today, Date.tomorrow)

        room_values_for_changed_room = room_values[room_id.to_s]

        # Info: We ask for data from today. Thus, we have to check the 2nd entry..
        expect(room_values_for_changed_room[0]['avail']).to eq(1)
        expect(room_values_for_changed_room[1]['avail']).to eq(0)

        # Cleanup our mess..
        test_data = [ {'id' => room_id, 'days' => [{'avail' => 1}, {'avail' => 1}]} ]
        wired.update_rooms_values("1422356463", Date.tomorrow, test_data)

        # And check whether the cleanup worked.
        room_values = wired.fetch_rooms_values("1422356463", Date.today, Date.tomorrow, [room_id])
        room_values_for_changed_room = room_values[room_id.to_s]
        expect(room_values_for_changed_room[0]['avail']).to eq(1)
        expect(room_values_for_changed_room[1]['avail']).to eq(1)

        wired.release_token
      end

    end

    describe Plugin do

      let(:config) { Hash.new }

      let(:plugin) { Plugin.new }

      before(:each) do
      end

      it 'should authenticate if the page path matches the regex' do
      end

      protected

    end
  end
end

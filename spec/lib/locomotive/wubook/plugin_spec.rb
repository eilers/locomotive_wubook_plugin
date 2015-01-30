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

      it 'should decode the error values' do
        expect(wired.decode_error(0)).to match ('Ok')
        expect(wired.decode_error(-1)).to match ('Authentication Failed')
      end

      it 'should aquire a token, validate it and return it afterwards' do
        token = wired.aquire_token
        expect(token).not_to be_nil

        expect(wired.is_token_valid(token)).to be_truthy

        wired.release_token(token)

        expect(wired.is_token_valid(token)).to be_falsey
      end

      it 'returns a list of rooms' do
        token = wired.aquire_token
        rooms = wired.fetch_rooms(token, "1422356463")
        expect(rooms).not_to be_nil
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

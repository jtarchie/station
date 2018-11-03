# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'time'

include Station

describe Station::Actions::CheckResource do
  context 'when given a brand new resource' do
    it 'returns the most recent version' do
      resource = Resource.new(
        name: '1ms',
        type: 'time',
        source: { 'interval' => '1ms' }
      )
      checker = Actions::CheckResource.new(resource: resource)
      checker.perform!
      checker.versions.size.should eq 1
    end
  end

  context 'when given a previous version' do
    it 'returns all the inbetween versions' do
      resource = Resource.new(
        name: '1ms',
        type: 'time',
        source: { 'interval' => '1ms' }
      )
      checker = Actions::CheckResource.new(resource: resource)
      checker.perform!(
        version: {
          'time' => Time.now.utc.xmlschema
        }
      )
      checker.versions.size.should be > 1
    end
  end
end

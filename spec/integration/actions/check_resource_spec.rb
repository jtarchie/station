# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'time'

describe Station::Actions::CheckResource do
  context 'when given a brand new resource' do
    it 'returns the most recent version' do
      resource = Station::Pipeline::Resource.new(
        name: 'mock',
        type: 'mock',
        source: {}
      )
      checker = described_class.new(resource: resource)
      result = checker.perform!
      expect(result.payload).to eq([
                                     { 'version' => '', 'privileged' => 'true' }
                                   ])
      expect(result.status).to eq Station::Status::SUCCESS
    end
  end

  context 'when given a previous version' do
    it 'returns all the inbetween versions' do
      resource = Station::Pipeline::Resource.new(
        name: 'mock',
        type: 'mock',
        source: {}
      )
      checker = described_class.new(resource: resource)
      result = checker.perform!(
        version: {
          'version' => 'some-version'
        }
      )
      expect(result.payload).to eq [
        { 'version' => 'some-version', 'privileged' => 'true' }
      ]
      expect(result.status).to eq Station::Status::SUCCESS
    end
  end
end

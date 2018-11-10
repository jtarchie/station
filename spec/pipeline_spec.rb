# frozen_string_literal: true

require 'spec_helper'

require 'yaml'

RSpec.describe 'When parsing a pipeline' do
  it 'understands resources' do
    payload = {
      'resources' => [
        { 'name' => 'testing', 'type' => 'git' }
      ]
    }.to_yaml
    pipeline = Station::Pipeline.from_yaml(payload)
    expect(pipeline.resources.size).to eq 1

    resource = pipeline.resources.first
    expect(resource.name).to eq 'testing'
    expect(resource.type).to eq 'git'
    expect(resource.source).to eq ({})
  end
end

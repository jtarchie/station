# frozen_string_literal: true

require 'spec_helper'

describe Station::ResourceTypes do
  include Station

  it 'supports the standard concourse types' do
    types = described_class.new
    expect(types.repository(name: 'time')).to eq 'concourse/time-resource:latest'
    expect(types.repository(name: 'git')).to eq 'concourse/git-resource:latest'
  end

  it 'allows custom resource type' do
    types = described_class.new
    types.add(
      name: 'pull-request',
      type: 'docker-image',
      source: {
        'repository' => 'jtarchie/pr'
      }
    )
    expect(types.repository(name: 'time')).to eq 'concourse/time-resource:latest'
    expect(types.repository(name: 'git')).to eq 'concourse/git-resource:latest'
    expect(types.repository(name: 'pull-request')).to eq 'jtarchie/pr:latest'
  end

  it 'allows custom resource type and tag' do
    types = described_class.new
    types.add(
      name: 'pull-request',
      type: 'docker-image',
      source: {
        'repository' => 'jtarchie/pr',
        'tag'        => 'testing'
      }
    )
    expect(types.repository(name: 'time')).to eq 'concourse/time-resource:latest'
    expect(types.repository(name: 'git')).to eq 'concourse/git-resource:latest'
    expect(types.repository(name: 'pull-request')).to eq 'jtarchie/pr:testing'
  end

  it 'allows custom resource types to override defaults' do
    types = described_class.new
    types.add(
      name: 'time',
      type: 'docker-image',
      source: {
        'repository' => 'jtarchie/time',
        'tag'        => 'testing'
      }
    )
    expect(types.repository(name: 'time')).to eq 'jtarchie/time:testing'
    expect(types.repository(name: 'git')).to eq 'concourse/git-resource:latest'
  end
end

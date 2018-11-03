# frozen_string_literal: true

require 'spec_helper'

include Station

describe Station::ResourceTypes do
  it 'supports the standard concourse types' do
    types = ResourceTypes.new
    types.repository(name: 'time').should eq 'concourse/time-resource:latest'
    types.repository(name: 'git').should eq 'concourse/git-resource:latest'
  end

  it 'allows custom resource type' do
    types = ResourceTypes.new
    types.add(
      name: 'pull-request',
      type: 'docker-image',
      source: {
        'repository' => 'jtarchie/pr'
      }
    )
    types.repository(name: 'time').should eq 'concourse/time-resource:latest'
    types.repository(name: 'git').should eq 'concourse/git-resource:latest'
    types.repository(name: 'pull-request').should eq 'jtarchie/pr:latest'
  end

  it 'allows custom resource type and tag' do
    types = ResourceTypes.new
    types.add(
      name: 'pull-request',
      type: 'docker-image',
      source: {
        'repository' => 'jtarchie/pr',
        'tag'        => 'testing'
      }
    )
    types.repository(name: 'time').should eq 'concourse/time-resource:latest'
    types.repository(name: 'git').should eq 'concourse/git-resource:latest'
    types.repository(name: 'pull-request').should eq 'jtarchie/pr:testing'
  end

  it 'allows custom resource types to override defaults' do
    types = ResourceTypes.new
    types.add(
      name: 'time',
      type: 'docker-image',
      source: {
        'repository' => 'jtarchie/time',
        'tag'        => 'testing'
      }
    )
    types.repository(name: 'time').should eq 'jtarchie/time:testing'
    types.repository(name: 'git').should eq 'concourse/git-resource:latest'
  end
end

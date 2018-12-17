# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe Station::Actions::Task do
  # platform
  # image_resource
  # run - path, args, dir, user
  it 'can have all the things' do
    config = Station::Pipeline::Job::Task::Config.new(
      platform: 'linux',
      image_resource: {
        type: 'docker-image',
        source: {
          'repository' => 'ubuntu',
          'tag' => 'latest'
        },
        params: {},
        version: {}
      },
      run: {
        path: 'bash',
        args: ['-c', 'env && echo "user: $(whoami)" && echo "path: $PWD" && echo "hello world"'],
        dir: 'testing',
        user: 'nobody'
      },
      params: {
        'NOTABLE' => 'THING'
      },
      inputs: [],
      outputs: [],
      caches: []
    )
    task = described_class.new(config: config)
    result = task.perform!(volumes: [])
    expect(result.stdout).to include 'user: nobody'
    expect(result.stdout).to include 'path: /tmp/build/task/testing'
    expect(result.stdout).to include 'hello world'
    expect(result.stdout).to include 'NOTABLE=THING'
    expect(result.stderr).to eq ''
  end
end

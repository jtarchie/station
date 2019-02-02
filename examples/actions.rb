# frozen_string_literal: true

require 'yaml'
require_relative '../lib/station'
require 'securerandom'

ENV['DEBUG'] = '1'

pipeline = Station::Pipeline.from_hash(YAML.safe_load(<<~YAML))
  resources:
  - name: my-repo
    type: git
    source:
      uri: https://github.com/jtarchie/station
  jobs:
  - name: testing
    plan:
    - get: repo
      resource: my-repo
    - task: run-tests
      config:
        inputs:
        - name: repo
          path: station
        outputs:
        - name: updated-repo
          path: another-station
        platform: linux
        image_resource:
          type: docker-image
          source:
            repository: ruby
        run:
          path: bash
          args:
            - -c
            - |
              set -eux
              cd station
              bundle install
              bundle exec rspec -t ~integration
    - put: my-repo
      params:
        repository: updated-repo
YAML

raise pipeline.errors.inspect unless pipeline.valid?

builder = Station::Builder::Jobs.new(pipeline: pipeline)
plan    = builder.plans['testing']

known_versions = Hash.new { |hash, key| hash[key] = [] }
volumes = Hash.new { |hash, key| hash[key] = File.expand_path(File.join(__dir__, '..', 'tmp', SecureRandom.hex)) }

executor = Station::Executor::Job.new(
  plan: plan,
  versions: known_versions,
  volumes: volumes
)
executor.perform!

puts 'cleaning up'
volumes.each do |_name, dir|
  system("rm -Rf #{dir}")
end

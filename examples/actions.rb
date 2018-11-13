# frozen_string_literal: true

require 'yaml'
require_relative '../lib/station'
require 'securerandom'

ENV['DEBUG'] = '1'

pipeline = Station::Pipeline.from_yaml(
  {
    'resources' => [
      { 'name' => 'repo', 'type' => 'git', 'source' => { 'uri' => 'https://github.com/jtarchie/station' } }
    ],
    'jobs' => [
      {
        'name' => 'testing',
        'plan' => [
          { 'get' => 'repo' }
        ]
      }
    ]
  }.to_yaml
)

builder = Station::Builder.new(pipeline: pipeline)
plan    = builder.plans['testing']

known_versions = Hash.new { |hash, key| hash[key] = [] }
volumes = Hash.new { |hash, key| hash[key] = File.expand_path(File.join(__dir__, '..', 'tmp', SecureRandom.hex)) }

executor = Station::Execute.new(
  plan: plan,
  versions: known_versions,
  volumes: volumes
)
executor.perform!

puts 'cleaning up'
volumes.each do |_name, dir|
  system("rm -Rf #{dir}")
end

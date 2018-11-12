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
results = Hash.new { |hash, key| hash[key] = [] }

while steps = plan.next(current: results)
  break if steps.empty?

  steps.each do |step|
    case step
    when Station::Actions::CheckResource
      result = step.perform!
      known_versions[step.resource.name] += result.payload
      results[step.to_s] = [Station::Status::SUCCESS]
    when Station::Actions::GetResource
      step.perform!(
        version: known_versions[step.resource.name].last,
        destination_dir: volumes[step.resource.name]
      )
      system("ls -asl #{volumes[step.resource.name]}")
      results[step.to_s] = [Station::Status::SUCCESS]
    end
  end
end

puts 'cleaning up'
volumes.each do |_name, dir|
  system("rm -Rf #{dir}")
end

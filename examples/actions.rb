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

steps = pipeline.jobs.first.plan.map do |step|
  case step
  when Station::Pipeline::Jobs::Get
    resource_name = step.get
    resource = pipeline.resources.find { |r| r.name == resource_name }
    [
      Station::Actions::CheckResource.new(resource: resource),
      Station::Actions::GetResource.new(resource: resource)
    ]
  end
end

known_versions = Hash.new { |hash, key| hash[key] = [] }
volumes = Hash.new { |hash, key| hash[key] = File.expand_path(File.join(__dir__, '..', 'tmp', SecureRandom.hex)) }

def process(steps, known_versions, volumes)
  steps.each do |step|
    case step
    when Array
      process(step, known_versions, volumes)
    when Station::Actions::CheckResource
      result = step.perform!
      known_versions[step.resource.name] += result.payload
    when Station::Actions::GetResource
      step.perform!(
          version: known_versions[step.resource.name].last,
          destination_dir: volumes[step.resource.name]
      )
      system("ls -asl #{volumes[step.resource.name]}")
    end
  end
end

process(steps, known_versions, volumes)

puts 'cleaning up'
volumes.each do |_name, dir|
  system("rm -Rf #{dir}")
end

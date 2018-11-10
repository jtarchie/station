# frozen_string_literal: true

require_relative '../lib/station'
require 'securerandom'

include Station
include Station::Actions

resource = Resource.new(
  name: 'repo',
  type: 'git',
  source: {
    'uri' => 'https://github.com/jtarchie/station'
  }
)

steps = [
  CheckResource.new(
    resource: resource
  ),
  GetResource.new(
    resource: resource
  )
]

known_versions = Hash.new { |hash, key| hash[key] = [] }
volumes = Hash.new { |hash, key| hash[key] = File.expand_path(File.join(__dir__, '..', 'tmp', SecureRandom.hex)) }

steps.each do |step|
  case step
  when CheckResource
    result = step.perform!
    known_versions[step.resource.name] += result.payload
  when GetResource
    step.perform!(
      version: known_versions[step.resource.name].last,
      destination_dir: volumes[step.resource.name]
    )
    system("ls -asl #{volumes[step.resource.name]}")
  end
end

puts 'cleaning up'
volumes.each do |_name, dir|
  system("rm -Rf #{dir}")
end

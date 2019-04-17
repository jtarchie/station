# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'When given a pipeline definition' do
  # class Volumes
  #   def initialize
  #     @volumes = {}
  #   end
    
  #   def path(resource_name:)
  #     @version[resource_name] ||= File.expand_path(File.join(__dir__, '..', '..', 'tmp', SecureRandom.hex))
  #   end
  # end

  # it 'runs it successfully' do
  #   pipeline = <<~YAML
  #     resources:
  #     - name: mock
  #       type: docker-image
  #       source:
  #         repository: concourse/mock-resource
  #     jobs:
  #     - name: first
  #       plan:
  #       - get: mock
  #         trigger: true
  #       - task: use-mock
  #         inputs:
  #         - name: mock
  #           path: alias-mock
  #         config:
  #           platform: linux
  #           image_resource:
  #             type: docker-image
  #             source:
  #               repository: ubuntu
  #           run:
  #             path: cat
  #             args: ['alias-mock/version']
  #       - put: mock
  #     - name: second
  #       plan:
  #       - get: mock
  #         passed: [ first ]
  #       - task: use-mock
  #         inputs:
  #         - name: mock
  #           path: alias-mock
  #         config:
  #           platform: linux
  #           image_resource:
  #             type: docker-image
  #             source:
  #               repository: ubuntu
  #           run:
  #             path: cat
  #             args: ['alias-mock/version']
  #   YAML

  #   builder  = Station::Builder::Jobs.new(pipeline: pipeline)
  #   versions = Versions.new
  #   volumes  = Volumes.new

  #   builder.plans.each do |job_name, plan|
  #     executor = Station::Executor::Job.new(
  #       plan: plan,
  #       versions: known_versions,
  #       volumes: volumes
  #     )
  #     executor.perform!
  #   end
  # end
end

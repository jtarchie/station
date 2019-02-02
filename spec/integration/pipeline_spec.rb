# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'When given a pipeline definition' do
  it 'runs it successfully' do
    pipeline = <<~YAML
      resources:
      - name: mock
        type: docker-image
        source:
          repository: concourse/mock-resource
      jobs:
      - name: first
        plan:
        - get: mock
          trigger: true
        - task: use-mock
          inputs:
          - name: mock
            path: alias-mock
          config:
            platform: linux
            image_resource:
              type: docker-image
              source:
                repository: ubuntu
            run:
              path: cat
              args: ['alias-mock/version']
        - put: mock
      - name: second
        plan:
        - get: mock
          passed: [ first ]
        - task: use-mock
          inputs:
          - name: mock
            path: alias-mock
          config:
            platform: linux
            image_resource:
              type: docker-image
              source:
                repository: ubuntu
            run:
              path: cat
              args: ['alias-mock/version']
    YAML
  end
end

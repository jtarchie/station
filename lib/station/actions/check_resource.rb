# frozen_string_literal: true

require 'json'

module Station
  module Actions
    class CheckResource
      Result = Struct.new(:payload, :stderr, keyword_init: true)
      attr_reader :resource

      def initialize(
        resource: Resource,
        resource_types: ResourceTypes.new
      )
        @resource = resource
        @resource_types = resource_types
      end

      def perform!(version: {})
        runner = DockerRunner.new(
          volumes: [],
          working_dir: '/tmp/build/12345',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/check']
        )
        runner.execute!(payload: {
                          source: @resource.source,
                          version: version
                        })
        Result.new(
          payload: JSON.parse(runner.stdout),
          stderr: runner.stderr
        )
      end
    end
  end
end

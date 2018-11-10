# frozen_string_literal: true

require 'json'
require 'tmpdir'

module Station
  module Actions
    class GetResource
      Result = Struct.new(:payload, :stderr, keyword_init: true)

      def initialize(
          resource: Resource,
          params: Hash,
          resource_types: ResourceTypes.new
        )
        @resource = resource
        @params = params
        @resource_types = resource_types
      end

      def perform!(version: {}, destination_dir:)
        runner = DockerRunner.new(
          volumes: [Volume.new(destination_dir, '/tmp/build/get')],
          working_dir: '/tmp/build/get',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/in', '/tmp/build/get']
        )
        runner.execute!(payload: {
                          source: @resource.source,
                          version: version,
                          params: @params
                        })
        Result.new(
          payload: JSON.parse(runner.stdout),
          stderr: runner.stderr
        )
      end
    end
  end
end

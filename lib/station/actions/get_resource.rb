# frozen_string_literal: true

require 'json'
require 'tmpdir'

module Station
  module Actions
    class GetResource
      Result = Struct.new(:payload, :stderr, keyword_init: true)

      attr_reader :resource, :params

      def initialize(
          resource: Resource,
          params: {},
          resource_types: ResourceTypes.new,
          runner_klass: Runner::Docker
        )
        @resource = resource
        @params = params
        @resource_types = resource_types
        @runner_klass = runner_klass
      end

      def perform!(version: {}, destination_dir:)
        runner = runner(destination_dir)
        runner.execute!(payload: {
                          source: @resource.source,
                          version: version,
                          params: @params
                        })
        result(runner)
      end

      private

      def runner(destination_dir)
        @runner_klass.new(
          volumes: [Runner::Volume.new(destination_dir, '/tmp/build/get')],
          working_dir: '/tmp/build/get',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/in', '/tmp/build/get']
        )
      end

      def result(runner)
        Result.new(
          payload: JSON.parse(runner.stdout),
          stderr: runner.stderr
        )
      end
    end
  end
end

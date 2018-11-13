# frozen_string_literal: true

require 'json'

module Station
  module Actions
    class CheckResource
      Result = Struct.new(:payload, :stderr, keyword_init: true)
      attr_reader :resource

      def initialize(
        resource: Resource,
        resource_types: ResourceTypes.new,
        runner_klass: Runner::Docker
      )
        @resource = resource
        @resource_types = resource_types
        @runner_klass = runner_klass
      end

      def perform!(version: {})
        runner = @runner_klass.new(
          volumes: [],
          working_dir: '/tmp/build/check',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/check']
        )
        runner.execute!(payload: {
                          source: @resource.source,
                          version: version
                        })
        result(runner)
      end

      private

      def result(runner)
        Result.new(
          payload: JSON.parse(runner.stdout),
          stderr: runner.stderr
        )
      end
    end
  end
end

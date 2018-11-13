# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'tmpdir'

module Station
  module Actions
    class PutResource
      Result = Struct.new(:payload, :stderr, keyword_init: true)
      attr_reader :params, :resource

      def initialize(
          resource: Resource,
          params: Hash,
          resource_types: ResourceTypes.new
        )
        @resource = resource
        @params = params
        @resource_types = resource_types
      end

      def perform!(version: {}, mounts_dir: Dir.mktmpdir)
        runner = Runner::Docker.new(
          volumes: [Runner::Volume.new(mounts_dir, '/tmp/build/put')],
          working_dir: '/tmp/build/put',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/out', '/tmp/build/put']
        )
        runner.execute!(payload: {
                          source: @resource.source,
                          version: version,
                          params: @params
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

# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'tmpdir'

module Station
  module Actions
    class PutResource
      Result = Struct.new(:payload, :stderr, keyword_init: true)
      attr_reader :mounts_dir

      def initialize(
          resource: Resource,
          params: Hash,
          mounts_dir: Dir.mktmpdir,
          resource_types: ResourceTypes.new
        )
        @resource = resource
        @params = params
        @mounts_dir = mounts_dir
        @resource_types = resource_types
      end

      def perform!(version: {})
        runner.execute!(payload: {
                          source: @resource.source,
                          version: version,
                          params: @params
                        })
        result(runner)
      end

      private

      def runner
        @runner ||= Runner::Docker.new(
          volumes: [Runner::Volume.new(mounts_dir, '/tmp/build/put')],
          working_dir: '/tmp/build/put',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/out', '/tmp/build/put']
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

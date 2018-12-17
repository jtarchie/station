# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'tmpdir'

module Station
  module Actions
    class PutResource
      Result = Struct.new(:payload, :stderr, :status, keyword_init: true)
      attr_reader :params, :resource

      def initialize(
          resource: Resource,
          params: Hash,
          resource_types: ResourceTypes.new,
          runner_klass: Runner::Docker
        )
        @resource = resource
        @params = params
        @resource_types = resource_types
        @runner_klass = runner_klass
      end

      def perform!(mounts_dir: Dir.mktmpdir)
        runner = @runner_klass.new(
          volumes: [Runner::Volume.new(from: mounts_dir, to: '/tmp/build/put')],
          working_dir: '/tmp/build/put',
          image: @resource_types.repository(name: @resource.type),
          command: ['/opt/resource/out', '/tmp/build/put']
        )
        runner.execute!(payload: {
                          source: @resource.source,
                          params: @params
                        })
        result(runner)
      end

      private

      def result(runner)
        Result.new(
          payload: JSON.parse(runner.stdout),
          stderr: runner.stderr,
          status: runner.status == 0 ? Station::Status::SUCCESS : Station::Status::FAILED
        )
      end
    end
  end
end

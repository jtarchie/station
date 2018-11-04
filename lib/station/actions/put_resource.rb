# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'tmpdir'

module Station
  module Actions
    class PutResource
      attr_reader :mounts_dir
      attr_reader :stdout
      attr_reader :stderr

      def initialize(
          resource: Resource,
          params: Hash,
          mounts_dir: Dir.mktmpdir,
          resource_types: ResourceTypes.new,
          stdout: StringIO.new,
          stderr: StringIO.new
        )
        @resource = resource
        @params = params
        @mounts_dir = mounts_dir
        @resource_types = resource_types
        @stdout = stdout
        @stderr = stderr
      end

      def perform!(version: {})
        @stdout, @stderr, = Open3.capture3(
          ['docker',
           'run', '-i', '--rm',
           '-v', "#{mounts_dir}:/tmp/build/put",
           '-w', '/tmp/build/put',
           '--privileged=false',
           @resource_types.repository(name: @resource.type),
           '/opt/resource/out', '/tmp/build/put'].shelljoin,
          stdin_data: StringIO.new({
            source: @resource.source,
            version: version,
            params: @params
          }.to_json)
        )
      end
    end
  end
end

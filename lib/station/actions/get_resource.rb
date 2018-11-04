# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'tmpdir'

module Station
  module Actions
    class GetResource
      attr_reader :destination_dir
      attr_reader :stdout
      attr_reader :stderr

      def initialize(
          resource: Resource,
          params: Hash,
          destination_dir: Dir.mktmpdir,
          resource_types: ResourceTypes.new,
          stdout: StringIO.new,
          stderr: StringIO.new
        )
        @resource = resource
        @params = params
        @destination_dir = destination_dir
        @resource_types = resource_types
        @stdout = stdout
        @stderr = stderr
      end

      def perform!(version: {})
        @stdout, @stderr, = Open3.capture3(
          ['docker',
           'run', '-i', '--rm',
           '-v', "#{@destination_dir}:/tmp/build/get",
           '-w', '/tmp/build/get',
           '--privileged=false',
           @resource_types.repository(name: @resource.type),
           '/opt/resource/in', '/tmp/build/get'].shelljoin,
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

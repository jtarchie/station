# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'tmpdir'
require 'json'

module Station
  module Actions
    class GetResource
      attr_reader :stdout
      attr_reader :stderr

      def initialize(
          resource: Resource,
          params: Hash,
          resource_types: ResourceTypes.new,
          stdout: StringIO.new,
          stderr: StringIO.new
        )
        @resource = resource
        @params = params
        @resource_types = resource_types
        @stdout = stdout
        @stderr = stderr
      end

      def perform!(version: {}, destination_dir: )
        @stdout, @stderr, = Open3.capture3(
          ['docker',
           'run', '-i', '--rm',
           '-v', "#{destination_dir}:/tmp/build/get",
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

      def payload
        JSON.parse(@stdout.to_s)
      end
    end
  end
end

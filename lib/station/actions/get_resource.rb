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

      def perform!(version: {}, destination_dir:)
        Open3.popen3(
          ['docker',
           'run', '-i', '--rm',
           '-v', "#{destination_dir}:/tmp/build/get",
           '-w', '/tmp/build/get',
           '--privileged=false',
           @resource_types.repository(name: @resource.type),
           '/opt/resource/in', '/tmp/build/get'].shelljoin
        ) do |stdin, stdout, stderr, wait_thr|
          stdin.write({
            source: @resource.source,
            version: version,
            params: @params
          }.to_json)
          stdin.close
          readers = [stdout, stderr]

          while !!wait_thr.status
            next if readers.empty?

            reader = IO.select(readers)[0][0]
            begin
              output = reader.read_nonblock(1024)
              print output if ENV['DEBUG']
              @stdout.write output if reader == stdout
              @stderr.write output if reader == stderr
            rescue EOFError
              readers.delete(reader)
            end
          end
        end
      end

      def payload
        JSON.parse(@stdout.string)
      end
    end
  end
end

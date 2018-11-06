# frozen_string_literal: true

require 'json'
require 'open3'
require 'shellwords'

module Station
  module Actions
    class CheckResource
      attr_reader :resource

      def initialize(
        resource: Resource,
        resource_types: ResourceTypes.new,
        stdout: StringIO.new,
        stderr: StringIO.new
      )
        @resource = resource
        @resource_types = resource_types
        @stdout = stdout
        @stderr = stderr
      end

      def perform!(version: {})
        Open3.popen3(
          ['docker',
           'run', '-i', '--rm',
           '--privileged=false',
           @resource_types.repository(name: @resource.type),
           '/opt/resource/check'].shelljoin
        ) do |stdin, stdout, stderr, wait_thr|
          stdin.write({ source: @resource.source, version: version }.to_json)
          stdin.close
          readers = [stdout, stderr]

          while !!wait_thr.status
            next if readers.length == 0
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

      def versions
        if @stdout
          JSON.parse(@stdout.string).map do |version|
            version.map { |k, v| [k, v.to_s] }.to_h
          end
        else
          []
        end
      end
    end
end
end

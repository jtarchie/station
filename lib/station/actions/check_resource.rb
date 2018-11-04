# frozen_string_literal: true

require 'json'
require 'open3'
require 'shellwords'

module Station
  module Actions
    class CheckResource
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
        @stdout, @stderr, = Open3.capture3(
          ['docker',
           'run', '-i', '--rm',
           '--privileged=false',
           @resource_types.repository(name: @resource.type),
           '/opt/resource/check'].shelljoin,
          stdin_data: StringIO.new({ source: @resource.source, version: version }.to_json)
        )
      end

      def versions
        if @stdout
          JSON.parse(@stdout.to_s).map do |version|
            version.map { |k, v| [k, v.to_s] }.to_h
          end
        else
          []
        end
      end
    end
end
end

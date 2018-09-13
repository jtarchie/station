require "json"

module Station
  module Actions
    class CheckResource
      def initialize(
        @resource : Resource,
        @resource_types : ResourceTypes = ResourceTypes.new,
        @stdout : IO::Memory = IO::Memory.new,
        @stderr : IO::Memory = IO::Memory.new
      )
      end

      def perform!(
        version : Hash(String, String) = {} of String => String
      )
        Process.run(
          command: "docker",
          args: ["run", "-i", "--rm", @resource_types.repository(@resource.type), "/opt/resource/check"],
          output: @stdout,
          error: @stderr,
          input: IO::Memory.new({source: @resource.source, version: version}.to_json)
        )
      end

      def versions : Array(Hash(String, String))
        if stdout = @stdout
          return JSON.parse(stdout.to_s).as_a.map do |version|
            version.as_h.to_a.map { |k, v| [k, v.as_s] }.to_h
          end
        else
          return [] of Hash(String, String)
        end
      end
    end
  end
end

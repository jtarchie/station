require "tmpdir"

module Station
  module Actions
    class GetResource
      getter destionation_dir : String

      def initialize(
        @resource : Resource,
        @params : Hash(String, String),
        @destionation_dir : String = Dir.mktmpdir,
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
          args: [
            "run", "-i", "--rm",
            "-v", "#{@destionation_dir}:/tmp/build/get",
            "-w", "/tmp/build/get",
            @resource_types.repository(@resource.type),
            "/opt/resource/in", "/tmp/build/get",
          ],
          output: @stdout,
          error: @stderr,
          input: IO::Memory.new({
            source:  @resource.source,
            version: version,
            params:  @params,
          }.to_json)
        )
      end

      def version : Hash(String, String)
        payload.version
      end

      def metadata : Array(NamedTuple(name: String, value: String))
        payload.metadata
      end

      private def payload : Payload
        @payload ||= Payload.from_json(@stdout.to_s)
      end

      private class Payload
        JSON.mapping(
          version: Hash(String, String),
          metadata: Array(NamedTuple(name: String, value: String))
        )
      end
    end
  end
end

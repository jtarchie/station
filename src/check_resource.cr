require "json"

module Station
  class CheckResource
    property stdout : IO::Memory = IO::Memory.new
    property stderr : IO::Memory = IO::Memory.new

    def initialize(@resource : Resource)
    end

    def perform!(
      version : Hash(String, String) = {} of String => String
    )
      Process.run(
        command: "docker",
        args: ["run", "-i", "--rm", "concourse/#{@resource.type}-resource", "/opt/resource/check"],
        output: @stdout,
        error: @stderr,
        input: IO::Memory.new({source: @resource.source, version: version }.to_json)
      )
    end

    def versions : Array(Hash(String, String))
      if stdout = @stdout
        return JSON.parse(stdout.to_s).as_a.map do |version|
          version.as_h.to_a.map {|k, v| [k, v.as_s] }.to_h
        end
      else
        return [] of Hash(String, String)
      end
    end
  end
end

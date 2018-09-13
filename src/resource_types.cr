module Station
  class ResourceTypes
    def initialize
      @images = {} of String => NamedTuple(repository: String, tag: String)
    end

    def repository(name : String)
      return "#{@images[name][:repository]}:#{@images[name][:tag]}" if @images.has_key?(name)
      return "concourse/#{name}-resource:latest"
    end

    def add(name : String, type : String, source : Hash(String, String))
      @images[name] = {
        repository: source["repository"],
        tag:        source.fetch("tag", "latest"),
      }
    end
  end
end

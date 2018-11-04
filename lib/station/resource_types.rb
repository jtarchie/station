# frozen_string_literal: true

module Station
  class ResourceTypes
    Image = Struct.new(:repository, :tag, keyword_init: true)

    def initialize
      @images = {}
    end

    def repository(name: String)
      return "#{@images[name][:repository]}:#{@images[name][:tag]}" if @images.key?(name)

      "concourse/#{name}-resource:latest"
    end

    def add(name: String, type: String, source: Hash)
      @images[name] = Image.new(
        repository: source['repository'],
        tag:        source.fetch('tag', 'latest')
      )
    end
  end
end

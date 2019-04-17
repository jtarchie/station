module Station
  class Versions
    def initialize
      @versions = {}
    end

    def add(
      version:,
      resource_name:,
      job: nil
    )
      if job
        
      @versions[resource_name] = version
    end

    def latest(
      resource_name:,
      jobs:
    )
      @versions.fetch(resource_name, {})
    end
  end
end
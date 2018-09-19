module Station
  class Resource
    getter name : String
    getter type : String
    getter source : Hash(String, String)

    def initialize(
      @name : String,
      @type : String,
      @source : Hash(String, String)
    )
    end
  end
end

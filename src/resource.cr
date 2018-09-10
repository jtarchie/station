module Station
  class Resource
    property name : String?
    property type : String?
    property source : Hash(String, String)

    def initialize(
      @name : String,
      @type : String,
      @source : Hash(String, String)
    )
    end
  end
end

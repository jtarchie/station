# frozen_string_literal: true

module Station
  class Resource
    attr_reader :name
    attr_reader :type
    attr_reader :source

    def initialize(
      name: String,
      type: String,
      source: Hash
    )
      @name = name
      @type = type
      @source = source
    end
  end
end

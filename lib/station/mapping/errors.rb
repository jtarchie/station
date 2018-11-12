# frozen_string_literal: true

module Station
  class Mapping
    class RequiredValue < StandardError
      def initialize(name)
        super("'#{name}' is a required value")
      end
    end
    class RequiredType < StandardError
      def initialize(name, value, type)
        super("'#{name}' is of type '#{value.class}', but needs to be of type '#{type}'")
      end
    end
    class UnknownProperty < StandardError
      def initialize(name)
        super("'#{name}' is an unknown property or collection")
      end
    end
  end
end

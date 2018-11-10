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
    UnknownProperty = Class.new(StandardError)

    CustomHashType = Struct.new(:key, :value, keyword_init: true) do
      def ===(rhs)
        rhs.is_a?(Hash) &&
          rhs.keys.all? { |k| key === k } &&
          rhs.values.all? { |v| value === v }
      end
    end

    CustomArrayType = Struct.new(:value, keyword_init: true) do
      def ===(rhs)
        rhs.is_a?(Array) &&
          rhs.all? { |v| value === v }
      end
    end

    CustomBooleanType = Class.new do
      def ===(rhs)
        TrueClass === rhs || FalseClass === rhs
      end
    end

    CustomUnionType = Struct.new(:types, keyword_init: true) do
      def ===(rhs)
        types.any? { |t| t === rhs }
      end

      def new(value)
        types.lazy.map do |type|
          begin
            type.new(value)
          rescue UnknownProperty
            nil
          end
        end.find do |v|
          v != nil
        end
      end
    end

    def self.Hash(key, value)
      CustomHashType.new(key: key, value: value)
    end

    def self.Array(value)
      CustomArrayType.new(value: value)
    end

    def self.Union(*types)
      CustomUnionType.new(types: types)
    end

    def self.boolean
      CustomBooleanType.new
    end

    Expectation = Struct.new(:type, :required, :default, keyword_init: true) do
      def matches?(value)
        type === value
      end

      def value(value)
        return value unless type.respond_to?(:new)

        type.new(value)
      end
    end

    CollectionExpectation = Struct.new(:type, :required, :default, keyword_init: true) do
      def matches?(value)
        return false unless Array === value

        value.all? { |v| Hash === v }
      end

      def value(value)
        value.map do |v|
          type.new(v)
        end
      end
    end

    def self.collections
      @collections ||= {}
    end

    def self.collection(name, type, required: false, default: -> { [] })
      collections[name.to_s] = CollectionExpectation.new(
        type: type,
        required: required,
        default: default
      )
      define_method(name.to_s) do
        @values.fetch(name.to_s, self.class.collections[name.to_s].value(default.call))
      end
    end

    def self.properties
      @properties ||= {}
    end

    def self.property(name, type, required: false, default: -> {})
      properties[name.to_s] = Expectation.new(
        type: type,
        required: required,
        default: default
      )
      define_method(name.to_s) do
        @values.fetch(name.to_s, default.call)
      end
    end

    def initialize(options = {})
      @values = {}
      properties = self.class.properties
      collections = self.class.collections

      options.each do |name, value|
        if expect = properties[name.to_s]
          raise RequiredType.new(name, value, expect.type) unless expect.matches?(value)

          @values[name.to_s] = expect.value(value)
        elsif expect = collections[name.to_s]
          raise RequiredType.new(name, value, expect.type) unless expect.matches?(value)

          @values[name.to_s] = expect.value(value)
        else
          raise UnknownProperty
        end
      end

      properties.each do |name, expect|
        raise RequiredValue.new(name) if expect.required && !@values.key?(name)
      end
      collections.each do |name, expect|
        raise RequiredValue.new(name) if expect.required && !@values.key?(name)
      end
    end

    def self.===(rhs)
      keys = collections.keys + properties.keys
      (keys - rhs.keys).length > 0
    end
  end
end

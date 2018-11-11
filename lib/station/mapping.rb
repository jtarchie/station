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

    CustomHashType = Struct.new(:key, :value, keyword_init: true) do
      def matches?(rhs)
        rhs.is_a?(Hash) &&
          rhs.keys.all? { |k| key === k } &&
          rhs.values.all? { |v| value === v }
      end
    end

    CustomArrayType = Struct.new(:value, keyword_init: true) do
      def matches?(rhs)
        rhs.is_a?(Array) &&
          rhs.all? { |v| value === v }
      end
    end

    CustomBooleanType = Class.new do
      def matches?(rhs)
        TrueClass === rhs || FalseClass === rhs
      end
    end

    CustomUnionType = Struct.new(:types, keyword_init: true) do
      def matches?(rhs)
        types.any? do |t|
          (t.respond_to?(:matches?) && t.matches?(rhs)) || t === rhs
        end
      end

      def new(value)
        evals = types.lazy.map do |type|
          type.new(value)
                rescue UnknownProperty => e
                  e
        end
        assert = evals.find do |v|
          !(UnknownProperty === v)
        end
        return assert if assert

        raise(evals.find do |v|
          UnknownProperty === v
        end)
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
        return type.matches?(value) if type.respond_to?(:matches?)

        type === value
      end

      def value(value)
        return value if Hash == type
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
          raise UnknownProperty, name
        end
      end

      properties.each do |name, expect|
        raise RequiredValue, name if expect.required && !@values.key?(name)
      end
      collections.each do |name, expect|
        raise RequiredValue, name if expect.required && !@values.key?(name)
      end
    end

    def self.matches?(rhs)
      keys = collections.keys + properties.keys
      leftovers = rhs.keys.map(&:to_s) - keys
      leftovers.empty?
    end
  end
end

# frozen_string_literal: true

module Station
  class Mapping
    RequiredValue = Class.new(RuntimeError)
    RequiredType = Class.new(RuntimeError)
    UnknownProperty = Class.new(RuntimeError)
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

    def self.Hash(key, value)
      CustomHashType.new(key: key, value: value)
    end

    def self.Array(value)
      CustomArrayType.new(value: value)
    end

    Expectation = Struct.new(:type, :required, :default, keyword_init: true) do
      def matches?(value)
        type === value
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
          raise RequiredType unless expect.matches?(value)

          @values[name.to_s] = value
        elsif expect = collections[name.to_s]
          raise RequiredType unless expect.matches?(value)

          @values[name.to_s] = expect.value(value)
        else
          raise UnknownProperty
        end
      end

      properties.each do |name, expect|
        raise RequiredValue if expect.required && !@values.key?(name)
      end
      collections.each do |name, expect|
        raise RequiredValue if expect.required && !@values.key?(name)
      end
    end
  end
end

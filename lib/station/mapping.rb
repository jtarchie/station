# frozen_string_literal: true

require_relative 'mapping/errors'
require_relative 'mapping/custom_types'
# rubocop:disable Style/CaseEquality
module Station
  class Mapping
    def self.Hash(key, value) # rubocop:disable Naming/MethodName
      CustomHashType.new(key: key, value: value)
    end

    def self.Array(value) # rubocop:disable Naming/MethodName
      CustomArrayType.new(value: value)
    end

    def self.Union(*types) # rubocop:disable Naming/MethodName
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
        @values.fetch(name.to_s, self.class.collections[name.to_s].value(instance_eval(&default)))
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
        @values.fetch(name.to_s, instance_eval(&default))
      end
    end

    def initialize(options = {})
      @values = {}
      properties = self.class.properties
      collections = self.class.collections

      options.each do |name, value|
        check_expectation(collections, name, properties, value)
      end

      check_required_value(collections, properties)
    end

    def self.matches?(rhs)
      keys = collections.keys + properties.keys
      leftovers = rhs.keys.map(&:to_s) - keys
      leftovers.empty?
    end

    private

    def check_required_value(collections, properties)
      properties.each do |name, expect|
        raise RequiredValue, name if expect.required && !@values.key?(name)
      end
      collections.each do |name, expect|
        raise RequiredValue, name if expect.required && !@values.key?(name)
      end
    end

    def check_expectation(collections, name, properties, value)
      expect = properties[name.to_s] || collections[name.to_s]

      raise UnknownProperty, name unless expect
      raise RequiredType.new(name, value, expect.type) unless expect.matches?(value)

      @values[name.to_s] = expect.value(value)
    end
  end
end
# rubocop:enable Style/CaseEquality

# frozen_string_literal: true

# rubocop:disable Style/CaseEquality
module Station
  class Mapping
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
  end
end
# rubocop:enable Style/CaseEquality

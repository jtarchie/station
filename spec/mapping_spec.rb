# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'when creating a mapping' do
  context 'properties' do
    it 'handles default values' do
      klass = Class.new(Station::Mapping) do
        property :name, String, default: -> { 'default' }
      end
      obj = klass.new
      expect(obj.name).to eq 'default'

      obj = klass.new(name: 'custom')
      expect(obj.name).to eq 'custom'
    end

    it 'handles required values' do
      klass = Class.new(Station::Mapping) do
        property :name, String, required: true
      end
      expect {
        obj = klass.new
      }.to raise_error(Station::Mapping::RequiredValue)

      expect {
        obj = klass.new(name: 'custom')
      }.to_not raise_error
    end

    it 'handles specific types' do
      klass = Class.new(Station::Mapping) do
        property :name, String
      end

      expect {
        obj = klass.new(name: 123)
      }.to raise_error(Station::Mapping::RequiredType)
    end
  end

  context 'collections' do
    it 'handles default values' do
      klass = Class.new(Station::Mapping) do
        class Person < Station::Mapping
          property :name, String
          property :age, Integer, default: -> { 100 }
        end

        collection :people, Person, default: -> { [ {name: 'JT' }] }
      end
      obj = klass.new
      expect(obj.people.size).to eq 1
      expect(obj.people[0].name).to eq 'JT'
      expect(obj.people[0].age).to eq 100

      obj = klass.new(people: [{name: 'Bob', age: 101}])
      expect(obj.people.size).to eq 1
      expect(obj.people[0].name).to eq 'Bob'
      expect(obj.people[0].age).to eq 101
    end

    it 'handles required values' do
      klass = Class.new(Station::Mapping) do
        class Person < Station::Mapping
          property :name, String
          property :age, Integer
        end

        collection :people, Person, required: true
      end
      expect {
        obj = klass.new
      }.to raise_error(Station::Mapping::RequiredValue)

      expect {
        obj = klass.new(people: [{name: 'Bob', age: 101}])
      }.to_not raise_error
    end

    it 'handles specific types' do
      klass = Class.new(Station::Mapping) do
        class Person < Station::Mapping
          property :name, String
          property :age, Integer
        end

        collection :people, Person, required: true
      end

      expect {
        obj = klass.new(people: 123)
      }.to raise_error(Station::Mapping::RequiredType)
    end

    it 'defaults to an empty array' do
      klass = Class.new(Station::Mapping) do
        class Person < Station::Mapping
          property :name, String
          property :age, Integer
        end

        collection :people, Person
      end

      obj = klass.new
      expect(obj.people).to eq []
    end
  end

  it 'fails with an undefined property' do
    klass = Class.new(Station::Mapping)

    expect {
      obj = klass.new(people: 123)
    }.to raise_error(Station::Mapping::UnknownProperty)
  end
end

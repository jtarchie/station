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
      expect do
        obj = klass.new
      end.to raise_error(Station::Mapping::RequiredValue)

      expect do
        obj = klass.new(name: 'custom')
      end.not_to raise_error
    end

    it 'handles specific types' do
      klass = Class.new(Station::Mapping) do
        property :name, String
      end

      expect do
        obj = klass.new(name: 123)
      end.to raise_error(Station::Mapping::RequiredType)
    end

    context 'when type is specified as Hash' do
      it 'handles String => String' do
        klass = Class.new(Station::Mapping) do
          property :source, Hash(String, String)
        end

        obj = klass.new(source: { 'name' => 'value' })
        expect(obj.source).to eq('name' => 'value')

        expect do
          obj = klass.new(source: { 123 => 123 })
        end.to raise_error(Station::Mapping::RequiredType)
      end
    end

    context 'when type is specified as Array' do
      it 'handles list of String' do
        klass = Class.new(Station::Mapping) do
          property :names, Array(String)
        end

        obj = klass.new(names: %w[Al Bob])
        expect(obj.names).to eq(%w[Al Bob])

        expect do
          obj = klass.new(names: [1, 2, 3])
        end.to raise_error(Station::Mapping::RequiredType)
      end
    end

    context 'when the type is specified as Boolean' do
      it 'handles true or false' do
        klass = Class.new(Station::Mapping) do
          property :surprise, boolean
        end

        obj = klass.new(surprise: true)
        expect(obj.surprise).to be_truthy

        obj = klass.new(surprise: false)
        expect(obj.surprise).to be_falsey

        expect do
          obj = klass.new(surprise: 'testing')
        end.to raise_error(Station::Mapping::RequiredType)
      end
    end
  end

  context 'collections' do
    it 'handles default values' do
      klass = Class.new(Station::Mapping) do
        class Person < Station::Mapping
          property :name, String
          property :age, Integer, default: -> { 100 }
        end

        collection :people, Person, default: -> { [{ name: 'JT' }] }
      end
      obj = klass.new
      expect(obj.people.size).to eq 1
      expect(obj.people[0].name).to eq 'JT'
      expect(obj.people[0].age).to eq 100

      obj = klass.new(people: [{ name: 'Bob', age: 101 }])
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
      expect do
        obj = klass.new
      end.to raise_error(Station::Mapping::RequiredValue)

      expect do
        obj = klass.new(people: [{ name: 'Bob', age: 101 }])
      end.not_to raise_error
    end

    it 'handles specific types' do
      klass = Class.new(Station::Mapping) do
        class Person < Station::Mapping
          property :name, String
          property :age, Integer
        end

        collection :people, Person, required: true
      end

      expect do
        obj = klass.new(people: 123)
      end.to raise_error(Station::Mapping::RequiredType)
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

    expect do
      obj = klass.new(people: 123)
    end.to raise_error(Station::Mapping::UnknownProperty)
  end

  context 'when handling a union of mappings' do
    it 'parses to the appropriate mapping' do
      klass = Class.new(Station::Mapping) do
        class Tree < Station::Mapping
          property :leaves, Integer
        end

        class Flower < Station::Mapping
          property :flowers, Integer
        end

        Plant = Union(Tree, Flower)

        property :plant, Plant
        collection :plants, Plant
      end

      obj = klass.new(plant: {leaves: 1})
      expect(obj.plant.leaves).to eq 1
      expect(obj.plant).to be_instance_of(Tree)

      obj = klass.new(plant: {flowers: 1})
      expect(obj.plant.flowers).to eq 1
      expect(obj.plant).to be_instance_of(Flower)

      obj = klass.new(plants: [{leaves: 1}, {flowers: 2}])
      expect(obj.plants[0]).to be_instance_of(Tree)
      expect(obj.plants[0].leaves).to eq 1
      expect(obj.plants[1]).to be_instance_of(Flower)
      expect(obj.plants[1].flowers).to eq 2
    end
  end
end

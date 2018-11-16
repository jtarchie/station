# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Station::Builder::Jobs do
  context 'when step is a put' do
    it 'performs a put' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'put' => 'test-resource',
                'params' => {
                  'key' => 'value'
                }
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      steps = plans['test-job'].steps.first.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::PutResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[0].ref.params).to eq('key' => 'value')
    end

    it 'allows a put to have a resource alias' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'put' => 'not-the-original-name',
                'resource' => 'test-resource',
                'params' => {
                  'key' => 'value'
                }
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      steps = plans['test-job'].steps.first.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::PutResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[0].ref.params).to eq('key' => 'value')
    end
  end

  context 'when step is a get' do
    it 'performs a check and get' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'get' => 'test-resource',
                'params' => {
                  'key' => 'value'
                }
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      steps = plans['test-job'].steps.first.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::CheckResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[1].ref).to be_instance_of Station::Actions::GetResource
      expect(steps[1].ref.resource.name).to eq 'test-resource'
      expect(steps[1].ref.params).to eq('key' => 'value')
    end

    it 'allows a get to have a resource alias' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'get' => 'not-the-original-name',
                'resource' => 'test-resource',
                'params' => {
                  'key' => 'value'
                }
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      steps = plans['test-job'].steps.first.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::CheckResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[1].ref).to be_instance_of Station::Actions::GetResource
      expect(steps[1].ref.resource.name).to eq 'test-resource'
      expect(steps[1].ref.params).to eq('key' => 'value')
    end
  end

  context 'when step is a do' do
    it 'setups steps in serial' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'do' => [{
                  'put' => 'not-the-original-name',
                  'resource' => 'test-resource',
                  'params' => {
                    'key' => 'value'
                  }
                }]
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      serial = plans['test-job'].steps.first
      expect(serial).to be_instance_of Station::Planner::Serial

      steps = serial.steps.first.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::PutResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[0].ref.params).to eq('key' => 'value')
    end
  end

  context 'when step is an aggregate' do
    it 'setups steps in parallel' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'aggregate' => [{
                  'put' => 'not-the-original-name',
                  'resource' => 'test-resource',
                  'params' => {
                    'key' => 'value'
                  }
                }]
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      aggregate = plans['test-job'].steps.first
      expect(aggregate).to be_instance_of Station::Planner::Parallel

      steps = aggregate.steps.first.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::PutResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[0].ref.params).to eq('key' => 'value')
    end
  end

  context 'when step is a try' do
    it 'setups a single serial step' do
      pipeline = Station::Pipeline.from_hash(
        'resources' => [
          { 'name' => 'test-resource', 'type' => 'test-type' }
        ],
        'jobs' => [
          {
            'name' => 'test-job',
            'plan' => [
              {
                'try' => {
                  'put' => 'not-the-original-name',
                  'resource' => 'test-resource',
                  'params' => {
                    'key' => 'value'
                  }
                }
              }
            ]
          }
        ]
      )

      builder = described_class.new(pipeline: pipeline)
      plans = builder.plans
      try = plans['test-job'].steps.first
      expect(try).to be_instance_of Station::Planner::Try

      steps = try.steps.steps
      expect(steps[0].ref).to be_instance_of Station::Actions::PutResource
      expect(steps[0].ref.resource.name).to eq 'test-resource'
      expect(steps[0].ref.params).to eq('key' => 'value')
    end
  end
end

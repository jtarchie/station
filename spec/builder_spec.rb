# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe Station::Builder do
  context 'when step is a get' do
    it 'performs a check and get' do
      pipeline = Station::Pipeline.from_yaml({
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
      }.to_yaml)

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
      pipeline = Station::Pipeline.from_yaml({
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
      }.to_yaml)

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
end
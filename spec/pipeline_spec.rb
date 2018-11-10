# frozen_string_literal: true

require 'spec_helper'

require 'yaml'

RSpec.describe 'When parsing a pipeline' do
  it 'understands resources' do
    payload = {
      'resources' => [
        { 'name' => 'testing', 'type' => 'git' }
      ]
    }.to_yaml
    pipeline = Station::Pipeline.from_yaml(payload)
    expect(pipeline.resources.size).to eq 1

    resource = pipeline.resources.first
    expect(resource.name).to eq 'testing'
    expect(resource.type).to eq 'git'
    expect(resource.source).to eq ({})
    expect(resource.version).to eq ({})
    expect(resource.check_every).to eq '1m'
    expect(resource.tags).to eq []
    expect(resource.webhook_token).to be_nil
  end

  it 'understands resource types' do
    payload = {
        'resource_types' => [
            { 'name' => 'testing', 'type' => 'git' }
        ]
    }.to_yaml
    pipeline = Station::Pipeline.from_yaml(payload)
    expect(pipeline.resource_types.size).to eq 1

    type = pipeline.resource_types.first
    expect(type.name).to eq 'testing'
    expect(type.type).to eq 'git'
    expect(type.source).to eq ({})
    expect(type.privileged).to be_falsey
    expect(type.params).to eq ({})
    expect(type.check_every).to eq '1m'
    expect(type.tags).to eq []
  end

  context 'with jobs' do
    it 'understand a job' do
      payload = {
          'jobs' => [
              {'name' => 'testing', 'plan' => [] }
          ]
      }.to_yaml
      pipeline = Station::Pipeline.from_yaml(payload)
      expect(pipeline.jobs.size).to eq 1

      job = pipeline.jobs.first
      expect(job.name).to eq 'testing'
      expect(job.plan).to eq []
      expect(job.serial).to be_falsey
      expect(job.build_logs_to_retain).to be_nil
      expect(job.serial_groups).to eq []
      expect(job.max_in_flight).to be_nil
      expect(job.public).to be_falsey
      expect(job.disable_manual_trigger).to be_falsey
      expect(job.interruptible).to be_falsey
    end
  end
end

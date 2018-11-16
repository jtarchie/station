# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'When parsing a pipeline' do
  it 'understands resources' do
    payload = {
      'resources' => [
        { 'name' => 'testing', 'type' => 'git' }
      ],
      'jobs' => [
          {'name' => 'testing', 'plan' => [{'get' => 'testing'}]}
      ]
    }.to_yaml
    pipeline = Station::Pipeline.from_yaml(payload)
    expect(pipeline.errors).to be_empty
    expect(pipeline).to be_valid
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
    expect(pipeline.errors).to be_empty
    expect(pipeline).to be_valid
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
    it 'understands a job' do
      payload = {
        'jobs' => [
          { 'name' => 'testing', 'plan' => [] }
        ]
      }.to_yaml
      pipeline = Station::Pipeline.from_yaml(payload)
      expect(pipeline.errors).to be_empty
      expect(pipeline).to be_valid
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

    it 'understands a step' do
      payload = {
        'resources' => [
          { 'name' => 'resource-a', 'type' => 'test' },
          { 'name' => 'resource-b', 'type' => 'test' },
          { 'name' => 'resource-c', 'type' => 'test' },
          { 'name' => 'resource-d', 'type' => 'test' },
          { 'name' => 'resource-e', 'type' => 'test' }
        ],
        'jobs' => [
          { 'name' => 'testing', 'plan' => [
            { 'get' => 'resource-a', 'attempts' => 1 },
            { 'put' => 'resource-b' },
            { 'task' => 'task-name', 'config' => { 'platform' => 'linux' } },
            { 'do' => [
              'get' => 'resource-c'
            ] },
            { 'try' => {
              'get' => 'resource-d'
            } },
            { 'aggregate' => [
              'get' => 'resource-e'
            ] }
          ] }
        ]
      }.to_yaml
      pipeline = Station::Pipeline.from_yaml(payload)
      expect(pipeline.errors).to be_empty
      expect(pipeline).to be_valid
      plan = pipeline.jobs[0].plan
      expect(plan.size).to eq 6
      expect(plan[0].get).to eq 'resource-a'
      expect(plan[1].put).to eq 'resource-b'
      expect(plan[2].task).to eq 'task-name'
      expect(plan[3].do[0].get).to eq 'resource-c'
      expect(plan[4].try.get).to eq 'resource-d'
      expect(plan[5].aggregate[0].get).to eq 'resource-e'
    end
  end

  context 'when validating the data' do
    it 'ensures gets reference a define resource' do
      pipeline = Station::Pipeline.from_yaml({
        'resources' => [],
        'jobs' => [{
          'name' => 'test',
          'plan' => [{ 'get' => 'not-named' }]
        }]
      }.to_yaml)
      expect(pipeline.errors).not_to be_empty
      expect(pipeline).not_to be_valid
    end

    it 'ensures puts reference a define resource' do
      pipeline = Station::Pipeline.from_yaml({
        'resources' => [],
        'jobs' => [{
          'name' => 'test',
          'plan' => [{ 'put' => 'not-named' }]
        }]
      }.to_yaml)
      # expect(pipeline.errors).not_to be_empty
      expect(pipeline).not_to be_valid
    end

    it 'ensures resources define are used' do
      pipeline = Station::Pipeline.from_yaml({
        'resources' => [{ 'name' => 'git', 'type' => 'git' }],
        'jobs' => []
      }.to_yaml)
      expect(pipeline.errors).not_to be_empty
      expect(pipeline).not_to be_valid
    end
  end
end

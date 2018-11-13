# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Station::Actions::PutResource do
  let(:resource) do
    Station::Pipeline::Resource.new(
      name: 'mock',
      type: 'mock',
      source: {
        'create_files' => {
          'source' => 'source'
        }
      }
    )
  end

  let(:instance) do
    instance_double('Station::Runner::Docker')
  end

  let(:klass) do
    class_double('Station::Runner::Docker')
      .as_stubbed_const(transfer_nested_constants: true)
  end

  before do
    allow(instance).to receive(:execute!)
    allow(instance).to receive(:stdout).and_return('{}')
    allow(instance).to receive(:stderr)
    allow(klass).to receive(:new).and_return(instance)
  end

  def perform
    put = described_class.new(
      resource: resource,
      params: {
        'create_files_via_params' => {
          'param' => 'param'
        }
      },
      runner_klass: klass
    )
    put.perform!(
      mounts_dir: '/custom/dir/name'
    )
  end

  it 'passes a destination directory' do
    expect(klass).to receive(:new) do |args|
      volumes = args[:volumes]

      expect(volumes[0].from).to eq '/custom/dir/name'
      expect(volumes[0].to).to eq '/tmp/build/put'

      command = args[:command]
      expect(command.last).to eq '/tmp/build/put'
    end.and_return(instance)
    perform
  end

  it 'executes the in command' do
    expect(klass).to receive(:new) do |args|
      command = args[:command]
      expect(command).to eq ['/opt/resource/out', '/tmp/build/put']
    end.and_return(instance)
    perform
  end

  it 'uses the custom resource image' do
    expect(klass).to receive(:new) do |args|
      image = args[:image]
      expect(image).to eq 'concourse/mock-resource:latest'
    end.and_return(instance)
    perform
  end

  it 'sets the working directory' do
    expect(klass).to receive(:new) do |args|
      dir = args[:working_dir]
      expect(dir).to eq '/tmp/build/put'
    end.and_return(instance)
    perform
  end

  it 'passes the version, params, and source' do
    expect(instance).to receive(:execute!) do |args|
      payload = args[:payload]
      expect(payload[:source]).to eq('create_files' => { 'source' => 'source' })
      expect(payload[:params]).to eq('create_files_via_params' => { 'param' => 'param' })
    end
    perform
  end
end

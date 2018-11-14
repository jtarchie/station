# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Station::Actions::CheckResource do
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
    allow(instance).to receive(:status)
    allow(klass).to receive(:new).and_return(instance)
  end

  def perform
    check = described_class.new(
      resource: resource,
      runner_klass: klass
    )
    check.perform!(
      version: {
        'version' => 'abcd123'
      }
    )
  end

  it 'contains no volumes' do
    expect(klass).to receive(:new) do |args|
      volumes = args[:volumes]
      expect(volumes).to be_empty
    end.and_return(instance)
    perform
  end

  it 'executes the check command' do
    expect(klass).to receive(:new) do |args|
      command = args[:command]
      expect(command).to eq ['/opt/resource/check']
    end.and_return(instance)
    perform
  end

  it 'sets the working directory' do
    expect(klass).to receive(:new) do |args|
      dir = args[:working_dir]
      expect(dir).to eq '/tmp/build/check'
    end.and_return(instance)
    perform
  end

  it 'passes the version and source' do
    expect(instance).to receive(:execute!) do |args|
      payload = args[:payload]
      expect(payload[:source]).to eq('create_files' => { 'source' => 'source' })
      expect(payload[:version]).to eq('version' => 'abcd123')
    end
    perform
  end

  context 'when it exits gracefully' do
    it 'has a status on the result' do
      allow(instance).to receive(:status).and_return(0)
      result = perform
      expect(result.status).to eq Station::Status::SUCCESS
    end
  end

  context 'when it fails' do
    it 'has a status on the result' do
      allow(instance).to receive(:status).and_return(1)
      result = perform
      expect(result.status).to eq Station::Status::FAILED
    end
  end
end

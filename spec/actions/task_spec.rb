# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Station::Actions::Task do
  let(:config) do
    Station::Pipeline::Job::Task::Config.new(
      platform: 'linux',
      run: {
        path: 'bash'
      },
      image_resource: {
        type: 'docker-image',
        source: {}
      },
      inputs: [
        { name: 'testing-input' },
        { name: 'testing-input-with-dir', path: 'custom-dir', optional: true }
      ]
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
    allow(instance).to receive(:stdout)
    allow(instance).to receive(:stderr)
    allow(instance).to receive(:status).and_return(0)
    allow(klass).to receive(:new).and_return(instance)
  end

  def perform(volumes: [Station::Runner::Volume.new(from: '/tmp', to: 'testing-input')])
    check = described_class.new(
      config: config,
      runner_klass: klass
    )
    check.perform!(
      volumes: volumes
    )
  end

  context 'when it has inputs' do
    fit 'requires the input to be defined as a volume' do
      result = perform(
        volumes: [
          Station::Runner::Volume.new(from: '/tmp', to: 'custom-dir')
        ]
      )
      expect(result.status).to eq Station::Status::ERROR
    end

    context 'when the input is optional' do
      it 'does not require the input to be defined as a volume' do
        result = perform(
          volumes: [
            Station::Runner::Volume.new(from: '/tmp', to: 'testing-input')
          ]
        )
        expect(result.status).to eq Station::Status::SUCCESS
      end
    end
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

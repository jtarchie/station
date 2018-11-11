# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Station::Actions::GetResource do
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

  let(:runner_klass) do
    Class.new do
      def self.init_options
        @@init_options
      end

      def self.exec_options
        @@exec_options
      end

      def initialize(options)
        @@init_options = options
      end

      def execute!(options)
        @@exec_options = options
      end

      def stdout
        '{}'
      end

      def stderr
        ''
      end
    end
  end

  before do
    get = described_class.new(
      resource: resource,
      params: {
        'create_files_via_params' => {
          'param' => 'param'
        }
      },
      runner_klass: runner_klass
    )
    get.perform!(
      version: {
        'version' => 'abcd123'
      },
      destination_dir: '/custom/dir/name'
    )
  end

  it 'passes a destination directory' do
    volumes = runner_klass.init_options[:volumes]

    expect(volumes[0].from).to eq '/custom/dir/name'
    expect(volumes[0].to).to eq '/tmp/build/get'

    command = runner_klass.init_options[:command]
    expect(command.last).to eq '/tmp/build/get'
  end

  it 'executes the in command' do
    command = runner_klass.init_options[:command]
    expect(command).to eq ['/opt/resource/in', '/tmp/build/get']
  end

  it 'uses the custom resource image' do
    image = runner_klass.init_options[:image]
    expect(image).to eq 'concourse/mock-resource:latest'
  end

  it 'sets the working directory' do
    dir = runner_klass.init_options[:working_dir]
    expect(dir).to eq '/tmp/build/get'
  end

  it 'passes the version, params, and source' do
    payload = runner_klass.exec_options[:payload]
    expect(payload[:source]).to eq('create_files' => { 'source' => 'source' })
    expect(payload[:params]).to eq('create_files_via_params' => { 'param' => 'param' })
    expect(payload[:version]).to eq('version' => 'abcd123')
  end
end

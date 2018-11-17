# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe Station::Actions::GetResource do
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
  # don't use Dir.mktmpdir as it cannot be volume mounted into `docker run`
  let(:base_dir) { File.expand_path(File.join('..', '..', 'tmp')) }

  it 'uses all the values' do
    destination_dir = File.join(base_dir, SecureRandom.hex)
    get = described_class.new(
      resource: resource,
      params: {
        'create_files_via_params' => {
          'param' => 'param'
        }
      }
    )
    result = get.perform!(
      version: {
        'version' => 'abcd123'
      },
      destination_dir: destination_dir
    )
    contents = File.read(File.join(destination_dir, 'version'))
    expect(contents.chomp).to eq 'abcd123'
    contents = File.read(File.join(destination_dir, 'param'))
    expect(contents.chomp).to eq 'param'
    contents = File.read(File.join(destination_dir, 'source'))
    expect(contents.chomp).to eq 'source'

    expect(result.payload).to eq('metadata' => nil, 'version' => { 'version' => 'abcd123' })
    expect(result.stderr).to include 'fetching version: abcd123'
    expect(result.status).to eq Station::Status::SUCCESS
  end
end

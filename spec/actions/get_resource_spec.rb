# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe Station::Actions::GetResource do
  let(:resource) do
    Station::Resource.new(
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
    get = described_class.new(
      resource: resource,
      destination_dir: File.join(base_dir, SecureRandom.hex),
      params: {
        'create_files_via_params' => {
          'param' => 'param'
        }
      }
    )
    get.perform!(
      version: {
        'version' => 'abcd123'
      }
    )
    contents = File.read(File.join(get.destination_dir, 'version'))
    expect(contents.chomp).to eq 'abcd123'
    contents = File.read(File.join(get.destination_dir, 'param'))
    expect(contents.chomp).to eq 'param'
    contents = File.read(File.join(get.destination_dir, 'source'))
    expect(contents.chomp).to eq 'source'
  end
end

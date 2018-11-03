# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe Station::Actions::GetResource do
  let(:resource) do
    Station::Resource.new(
      name: 'echo',
      type: 'echo',
      source: { 'key' => 'value' }
    )
  end
  # don't use Dir.mktmpdir as it cannot be volume mounted into `docker run`
  let(:base_dir) { File.expand_path(File.join('..', '..', 'tmp')) }

  it 'uses a destination directory' do
    get = described_class.new(
      resource: resource,
      destination_dir: File.join(base_dir, SecureRandom.hex),
      params: {}
    )
    get.perform!(
      version: {
        'ref' => 'abcd123'
      }
    )
    contents = File.read(File.join(get.destination_dir, 'version'))
    expect(contents.chomp).to eq '{ "ref": "abcd123" }'.chomp
  end

  it 'uses the params' do
  end
  it 'uses the version provided' do
  end
  it 'uses source' do
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

describe Station::Actions::PutResource do
  let(:resource) do
    Station::Resource.new(
      name: 'mock',
      type: 'mock',
      source: {
        'metadata' => [
          { 'name' => 'key', 'value' => 'value' }
        ]
      }
    )
  end
  # don't use Dir.mktmpdir as it cannot be volume mounted into `docker run`
  let(:base_dir) { File.expand_path(File.join('..', '..', 'tmp')) }

  it 'uses all the values' do
    put = described_class.new(
      resource: resource,
      mounts_dir: File.join(base_dir, 'mounts'),
      params: {}
    )
    put.perform!(
      version: {
        'version' => 'abcd123'
      }
    )

    expect(JSON.parse(put.stdout.to_s)).to eq ({ 'metadata' => [{ 'name' => 'key', 'value' => 'value' }], 'version' => { 'privileged' => 'true', 'version' => '' } })
    expect(put.stderr.to_s).to include 'pushing version'
  end
end
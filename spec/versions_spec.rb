require 'spec_helper'

RSpec.describe 'When keeping state of versions' do
  it 'retuns the latest version' do
    versions = Station::Versions.new
    versions.add(resource_name: 't', version: {'a' => 'b'})
    versions.add(resource_name: 't', version: {'c' => 'd'})
    versions.add(resource_name: 'a', version: {'e' => 'f'})

    expect(versions.latest(resource_name: 't')).to eq({'c' => 'd'})
    expect(versions.latest(resource_name: 'a')).to eq({'e' => 'f'})
    expect(versions.latest(resource_name: 'b')).to eq({})
  end

  context 'when a version has passed a specific job' do
    it 'returns with a passed constraint' do
      versions = Station::Versions.new
      versions.add(
        resource_name: 't', 
        version: {'a' => 'b'},
        job: 'a'
      )
      versions.add(
        resource_name: 't', 
        version: {'c' => 'd'},
        job: 'b'
      )
      expect(versions.latest(
        resource_name: 't',
        jobs: ['a']
      )).to eq({'a' => 'b'})
    end
  end
end
# frozen_string_literal: true

module Station
  module Runner
    Volume = Struct.new(:from, :to)
  end
end

require_relative 'runner/docker'

# frozen_string_literal: true

module Station
  module Runner
    Volume = Struct.new(:from, :to, keyword_init: true)
  end
end

require_relative 'runner/docker'

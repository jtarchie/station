# frozen_string_literal: true

module Station
  VERSION = '0.1.0'

  class Status
    UNSTARTED = 'unstarted'
    RUNNING = 'running'
    SUCCESS = 'success'
    FAILED = 'failed'
  end
end

require_relative 'station/actions'
require_relative 'station/resource_types'
require_relative 'station/planner'
require_relative 'station/runner'
require_relative 'station/builder'
require_relative 'station/mapping'
require_relative 'station/pipeline'

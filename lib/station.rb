# frozen_string_literal: true

module Station
  VERSION = '0.1.0'

  class Status
    FAILED = 'failed'
    ERROR = 'error'
    RUNNING = 'running'
    SUCCESS = 'success'
    UNSTARTED = 'unstarted'
  end
end

require_relative 'station/actions'
require_relative 'station/planner'
require_relative 'station/builder/jobs'
require_relative 'station/executor/job'
require_relative 'station/mapping'
require_relative 'station/pipeline'
require_relative 'station/resource_types'
require_relative 'station/runner'
require_relative 'station/versions'

# frozen_string_literal: true

module Station
  VERSION = '0.1.0'

  class Status
    Unstarted = 'unstarted'
    Running = 'running'
    Success = 'success'
    Failed = 'failed'
  end
end

require_relative 'station/actions'
require_relative 'station/resource'
require_relative 'station/resource_types'
require_relative 'station/planner'
require_relative 'station/runner'
require_relative 'station/mapping'
require_relative 'station/pipeline'

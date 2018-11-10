# frozen_string_literal: true

require 'ruby-enum'

module Station
  VERSION = '0.1.0'

  class Status
    include Ruby::Enum

    define :Unstarted, 'unstarted'
    define :Running, 'running'
    define :Success, 'success'
    define :Failed, 'failed'
  end
end

require_relative 'station/actions'
require_relative 'station/resource'
require_relative 'station/resource_types'
require_relative 'station/planner'
require_relative 'station/runner'

# TODO: Write documentation for `Station`
module Station
  VERSION = "0.1.0"

  enum Status
    Unstarted
    Running
    Success
    Failed
  end
end

require "./planner"
require "./resource"
require "./actions/check_resource"

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
require "./resource_types"
require "./actions/check_resource"
require "./actions/get_resource"

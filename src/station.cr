# TODO: Write documentation for `Station`
module Station
  VERSION = "0.1.0"

  enum Status
    Unstarted
    Pending
    Running
    Success
    Failed
  end
end

require "./planner"

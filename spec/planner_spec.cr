require "./spec_helper"

include Station::Planner::DSL

describe Station::Planner do

  context "a plan with a single step" do
    it "returns the step for execution when it hasn't started yet" do
      plan = serial { task :A }
      next_steps = plan.next()
      next_steps.should eq([:A])
    end
  end
end

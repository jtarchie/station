require "./spec_helper"

include Station
include Station::Planner::DSL

describe Station::Planner do
  context "a serial plan with a single step" do
    it "returns the step for execution when it hasn't started yet" do
      plan = serial { task :A }
      plan.next.should eq(["A"])
      plan.state.should eq Status::Unstarted
    end

    it "returns no steps when the step completes" do
      plan = serial { task :A }
      [Status::Success,
       Status::Failed,
       Status::Pending,
       Status::Running,
      ].each do |status|
        plan.next({:A, status}).should eq([] of String)
        plan.state({:A, status}).should eq(status)
      end
    end
  end

  context "a parallel plan with a single step" do
    it "returns the step for execution when it hasn't started yet" do
      plan = aggregate { task :A }
      plan.next.should eq(["A"])
      plan.state.should eq Status::Unstarted
    end

    it "returns no steps when the step completes" do
      plan = aggregate { task :A }
      [Status::Success,
       Status::Failed,
       Status::Pending,
       Status::Running,
      ].each do |status|
        plan.next({:A, status}).should eq([] of String)
        plan.state({:A, status}).should eq(status)
      end
    end
  end

  context "with composed serial and parallel" do
    plan = serial do
      aggregate do
        task :A
        task :B
        serial do
          task :C
          task :D
        end
        aggregate do
          task :E
          serial do
            task :F
            task :G
          end
        end
      end
      task :H
    end

    it "has an initial state" do
      plan.next.should eq ["A", "B", "C", "E", "F"]
    end
  end
end

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
       Status::Running,
      ].each do |status|
        state = { {"A", status} }.to_h
        plan.next(state).should eq([] of String)
        plan.state(state).should eq(status)
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
       Status::Running,
      ].each do |status|
        state = { {"A", status} }.to_h
        plan.next(state).should eq([] of String)
        plan.state(state).should eq(status)
      end
    end
  end

  context "a serial plan with two steps" do
    it "returns the step for execution when it hasn't started yet" do
      plan = serial { task :A; task :B }
      plan.next.should eq(["A"])
      plan.state.should eq Status::Unstarted

      state = { {"A", Status::Success} }.to_h
      plan.next(state).should eq(["B"])
      plan.state(state).should eq Status::Running
    end

    it "returns the completed state" do
      plan = serial { task :A; task :B }
      state = {
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Success

      state = {
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Failed

      state = {
        {"A", Status::Failed},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Failed
    end

    it "returns the running state" do
      plan = serial { task :A; task :B }
      state = {
        {"A", Status::Success},
        {"B", Status::Running},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Running
    end
  end

  context "a parallel plan with two steps" do
    it "returns the step for execution when it hasn't started yet" do
      plan = aggregate { task :A; task :B }
      plan.next.should eq(["A", "B"])
      plan.state.should eq Status::Unstarted

      state = { {"A", Status::Success} }.to_h
      plan.next(state).should eq(["B"])
      plan.state(state).should eq Status::Running

      state = { {"B", Status::Success} }.to_h
      plan.next(state).should eq(["A"])
      plan.state(state).should eq Status::Running

      state = { {"B", Status::Running} }.to_h
      plan.next(state).should eq(["A"])
      plan.state(state).should eq Status::Running
    end

    it "returns the completed state" do
      plan = aggregate { task :A; task :B }
      state = {
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Success

      state = {
        {"A", Status::Failed},
        {"B", Status::Success},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Failed

      state = {
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Failed
    end

    it "returns the running state" do
      plan = aggregate { task :A; task :B }
      state = {
        {"A", Status::Success},
        {"B", Status::Running},
      }.to_h
      plan.next(state).should eq([] of String)
      plan.state(state).should eq Status::Running
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
      plan.state.should eq Status::Unstarted
    end

    it "recommends the next steps on success" do
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B", "C", "E", "F"]
      plan.next({
        {"A", Status::Success},
        {"F", Status::Success},
      }.to_h).should eq ["B", "C", "E", "G"]
    end
  end
end

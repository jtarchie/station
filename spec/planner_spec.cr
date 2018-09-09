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
      plan.state({ {"A", Status::Success} }.to_h).should eq Status::Running
      plan.next({
        {"A", Status::Success},
        {"F", Status::Success},
      }.to_h).should eq ["B", "C", "E", "G"]
      plan.next({
        {"A", Status::Success},
        {"C", Status::Success},
        {"F", Status::Success},
      }.to_h).should eq ["B", "D", "E", "G"]
      plan.next({
        {"A", Status::Success},
        {"C", Status::Success},
        {"D", Status::Success},
        {"F", Status::Success},
      }.to_h).should eq ["B", "E", "G"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
        {"D", Status::Success},
        {"F", Status::Success},
      }.to_h).should eq ["E", "G"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
        {"D", Status::Success},
        {"F", Status::Success},
        {"G", Status::Success},
      }.to_h).should eq ["E"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
        {"D", Status::Success},
        {"E", Status::Success},
        {"F", Status::Success},
        {"G", Status::Success},
      }.to_h).should eq ["H"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
        {"D", Status::Success},
        {"E", Status::Success},
        {"F", Status::Success},
        {"G", Status::Success},
        {"H", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
        {"D", Status::Success},
        {"E", Status::Success},
        {"F", Status::Success},
        {"G", Status::Success},
        {"H", Status::Success},
      }.to_h).should eq Status::Success
    end

    it "recommends the correct steps on failure" do
      plan.next({ {"A", Status::Failed} }.to_h).should eq ["B", "C", "E", "F"]
      plan.state({ {"A", Status::Failed} }.to_h).should eq Status::Running
      plan.next({
        {"A", Status::Failed},
        {"B", Status::Failed},
      }.to_h).should eq ["C", "E", "F"]
      plan.next({
        {"A", Status::Failed},
        {"B", Status::Failed},
        {"C", Status::Failed},
      }.to_h).should eq ["E", "F"]
      plan.next({
        {"A", Status::Failed},
        {"B", Status::Failed},
        {"C", Status::Failed},
        {"E", Status::Failed},
        {"F", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Failed},
        {"B", Status::Failed},
        {"C", Status::Failed},
        {"E", Status::Failed},
        {"F", Status::Failed},
      }.to_h).should eq Status::Failed
    end
  end

  context "when on success step is defined" do
    it "only triggers when all serial steps are successful" do
      plan = serial do
        task :A
        task :B
        success do
          serial do
            task :C
          end
        end
      end
      plan.next.should eq ["A"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq ["C"]
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq Status::Running
      plan.next({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
      }.to_h).should eq Status::Success
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Failed},
      }.to_h).should eq Status::Failed
    end

    it "only triggers when all parallel steps are successful" do
      plan = aggregate do
        task :A
        task :B
        success do
          serial do
            task :C
          end
        end
      end
      plan.next.should eq ["A", "B"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq ["C"]
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq Status::Running
      plan.next({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
      }.to_h).should eq Status::Success
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Failed},
      }.to_h).should eq Status::Failed
    end
  end

  context "when on failure step is defined" do
    it "only triggers when either of steps fail serially" do
      plan = serial do
        task :A
        task :B
        failure do
          serial do
            task :C
          end
        end
      end
      plan.next.should eq ["A"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq Status::Success
      plan.next({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq ["C"]
      plan.next({
        {"A", Status::Failed},
        {"B", Status::Success},
      }.to_h).should eq ["C"]
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.next({
        {"A", Status::Success},
        {"B", Status::Failed},
        {"C", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
        {"C", Status::Success},
      }.to_h).should eq Status::Failed
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
        {"C", Status::Failed},
      }.to_h).should eq Status::Failed
    end

    it "only triggers when all parallel steps are successful" do
      plan = aggregate do
        task :A
        task :B
        success do
          serial do
            task :C
          end
        end
      end
      plan.next.should eq ["A", "B"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq ["C"]
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq Status::Running
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Success},
      }.to_h).should eq Status::Success
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
        {"C", Status::Failed},
      }.to_h).should eq Status::Failed
    end
  end

  context "when a finally step is specified" do
    it "always runs no matter the state for serial" do
      plan = serial do
        task :A
        finally do
          serial do
            task :B
          end
        end
      end

      plan.next.should eq ["A"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({ {"A", Status::Failed} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Failed},
        {"B", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Failed},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
    end

    it "always runs no matter the state for parallel" do
      plan = aggregate do
        task :A
        finally do
          serial do
            task :B
          end
        end
      end

      plan.next.should eq ["A"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({ {"A", Status::Failed} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Failed},
        {"B", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Failed},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
    end
  end

  context "the order precedence for success/failure and finally" do
    it "recommends success/failure before finally in serial" do
      plan = serial do
        task :A
        success { serial { task :B } }
        failure { serial { task :C } }
        finally { serial { task :D } }
      end

      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq ["D"]
      plan.next({ {"A", Status::Failed} }.to_h).should eq ["C"]
      plan.next({
        {"A", Status::Failed},
        {"C", Status::Success},
      }.to_h).should eq ["D"]
    end

    it "recommends success/failure before finally in parallel" do
      plan = aggregate do
        task :A
        success { serial { task :B } }
        failure { serial { task :C } }
        finally { serial { task :D } }
      end

      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq ["D"]
      plan.next({ {"A", Status::Failed} }.to_h).should eq ["C"]
      plan.next({
        {"A", Status::Failed},
        {"C", Status::Success},
      }.to_h).should eq ["D"]
    end
  end

  context "when defining a try statement" do
    it "always returns success" do
      plan = serial do
        try { serial { task :A } }
        task :B
      end

      plan.next.should eq ["A"]
      plan.next({ {"A", Status::Success} }.to_h).should eq ["B"]
      plan.state({ {"A", Status::Success} }.to_h).should eq Status::Running
      plan.next({ {"A", Status::Failed} }.to_h).should eq ["B"]
      plan.state({ {"A", Status::Failed} }.to_h).should eq Status::Running
      plan.next({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
      plan.next({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq [] of String
      plan.state({
        {"A", Status::Success},
        {"B", Status::Success},
      }.to_h).should eq Status::Success
      plan.state({
        {"A", Status::Failed},
        {"B", Status::Success},
      }.to_h).should eq Status::Success
    end

    it "works with parallel" do
      plan = aggregate do
        task :A
        try { aggregate { task :B } }
      end

      plan.next.should eq ["A", "B"]
      plan.state({
        {"A", Status::Success},
        {"B", Status::Failed},
      }.to_h).should eq Status::Success
      plan.state({
        {"A", Status::Failed},
        {"B", Status::Failed},
      }.to_h).should eq Status::Failed
    end
  end
end

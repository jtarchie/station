# frozen_string_literal: true

require 'spec_helper'

describe Station::Planner do
  include Station::Planner::DSL

  context 'a serial plan with a single step' do
    it "returns the step for execution when it hasn't started yet" do
      plan = serial { task :A }
      expect(plan.next).to eq([:A])
      expect(plan.state).to eq Station::Status::UNSTARTED
    end

    it 'returns no steps when the step completes' do
      plan = serial { task :A }
      [Station::Status::SUCCESS,
       Station::Status::FAILED,
       Station::Status::RUNNING].each do |status|
        state = { 'A' => [status] }
        expect(plan.next(current: state)).to eq([])
        expect(plan.state(current: state)).to eq(status)
      end
    end
  end

  context 'a parallel plan with a single step' do
    it "returns the step for execution when it hasn't started yet" do
      plan = aggregate { task :A }
      expect(plan.next).to eq([:A])
      expect(plan.state).to eq Station::Status::UNSTARTED
    end

    it 'returns no steps when the step completes' do
      plan = aggregate { task :A }
      [Station::Status::SUCCESS,
       Station::Status::FAILED,
       Station::Status::RUNNING].each do |status|
        state = { 'A' => [status] }
        expect(plan.next(current: state)).to eq([])
        expect(plan.state(current: state)).to eq(status)
      end
    end
  end

  context 'a serial plan with two steps' do
    it "returns the step for execution when it hasn't started yet" do
      plan = serial { task :A; task :B }
      expect(plan.next).to eq([:A])
      expect(plan.state).to eq Station::Status::UNSTARTED

      state = { 'A' => [Station::Status::SUCCESS] }
      expect(plan.next(current: state)).to eq([:B])
      expect(plan.state(current: state)).to eq Station::Status::RUNNING
    end

    it 'returns the completed state' do
      plan = serial { task :A; task :B }
      state = {
        'A' => [Station::Status::SUCCESS],
        'B' => [Station::Status::SUCCESS]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::SUCCESS

      state = {
        'A' => [Station::Status::SUCCESS],
        'B' => [Station::Status::FAILED]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::FAILED

      state = {
        'A' => [Station::Status::FAILED]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::FAILED
    end

    it 'returns the running state' do
      plan = serial { task :A; task :B }
      state = {
        'A' => [Station::Status::SUCCESS],
        'B' => [Station::Status::RUNNING]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::RUNNING
    end
  end

  context 'a parallel plan with two steps' do
    it "returns the step for execution when it hasn't started yet" do
      plan = aggregate { task :A; task :B }
      expect(plan.next).to eq(%i[A B])
      expect(plan.state).to eq Station::Status::UNSTARTED

      state = { 'A' => [Station::Status::SUCCESS] }
      expect(plan.next(current: state)).to eq([:B])
      expect(plan.state(current: state)).to eq Station::Status::RUNNING

      state = { 'B' => [Station::Status::SUCCESS] }
      expect(plan.next(current: state)).to eq([:A])
      expect(plan.state(current: state)).to eq Station::Status::RUNNING

      state = { 'B' => [Station::Status::RUNNING] }
      expect(plan.next(current: state)).to eq([:A])
      expect(plan.state(current: state)).to eq Station::Status::RUNNING
    end

    it 'returns the completed state' do
      plan = aggregate { task :A; task :B }
      state = {
        'A' => [Station::Status::SUCCESS],
        'B' => [Station::Status::SUCCESS]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::SUCCESS

      state = {
        'A' => [Station::Status::FAILED],
        'B' => [Station::Status::SUCCESS]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::FAILED

      state = {
        'A' => [Station::Status::SUCCESS],
        'B' => [Station::Status::FAILED]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::FAILED
    end

    it 'returns the running state' do
      plan = aggregate { task :A; task :B }
      state = {
        'A' => [Station::Status::SUCCESS],
        'B' => [Station::Status::RUNNING]
      }
      expect(plan.next(current: state)).to eq([])
      expect(plan.state(current: state)).to eq Station::Status::RUNNING
    end
  end

  context 'with composed serial and parallel' do
    let(:plan) do
      serial do
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
    end

    it 'has an initial state' do
      expect(plan.next).to eq %i[A B C E F]
      expect(plan.state).to eq Station::Status::UNSTARTED
    end

    it 'recommends the next steps on success' do
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq %i[B C E F]
      expect(plan.state(current: { 'A' => [Station::Status::SUCCESS] })).to eq Station::Status::RUNNING
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS]
                       })).to eq %i[B C E G]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS]
                       })).to eq %i[B D E G]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS],
                         'D' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS]
                       })).to eq %i[B E G]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS],
                         'D' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS]
                       })).to eq %i[E G]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS],
                         'D' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS],
                         'G' => [Station::Status::SUCCESS]
                       })).to eq [:E]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS],
                         'D' => [Station::Status::SUCCESS],
                         'E' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS],
                         'G' => [Station::Status::SUCCESS]
                       })).to eq [:H]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS],
                         'D' => [Station::Status::SUCCESS],
                         'E' => [Station::Status::SUCCESS],
                         'F' => [Station::Status::SUCCESS],
                         'G' => [Station::Status::SUCCESS],
                         'H' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::SUCCESS],
                          'D' => [Station::Status::SUCCESS],
                          'E' => [Station::Status::SUCCESS],
                          'F' => [Station::Status::SUCCESS],
                          'G' => [Station::Status::SUCCESS],
                          'H' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
    end

    it 'recommends the correct steps on failure' do
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq %i[B C E F]
      expect(plan.state(current: { 'A' => [Station::Status::FAILED] })).to eq Station::Status::RUNNING
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::FAILED]
                       })).to eq %i[C E F]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::FAILED],
                         'C' => [Station::Status::FAILED]
                       })).to eq %i[E F]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::FAILED],
                         'C' => [Station::Status::FAILED],
                         'E' => [Station::Status::FAILED],
                         'F' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::FAILED],
                          'B' => [Station::Status::FAILED],
                          'C' => [Station::Status::FAILED],
                          'E' => [Station::Status::FAILED],
                          'F' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end
  end

  context 'when on success step is defined' do
    it 'only triggers when all serial steps are successful' do
      plan = serial do
        task :A
        task :B
        success do
          serial do
            task :C
          end
        end
      end
      expect(plan.next).to eq [:A]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq [:C]
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::RUNNING
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end

    it 'only triggers when all parallel steps are successful' do
      plan = aggregate do
        task :A
        task :B
        success do
          serial do
            task :C
          end
        end
      end
      expect(plan.next).to eq %i[A B]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq [:C]
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::RUNNING
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end
  end

  context 'when on failure step is defined' do
    it 'only triggers when either of steps fail serially' do
      plan = serial do
        task :A
        task :B
        failure do
          serial do
            task :C
          end
        end
      end
      expect(plan.next).to eq [:A]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq [:C]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq [:C]
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED],
                         'C' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED],
                          'C' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::FAILED
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED],
                          'C' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end

    it 'only triggers when all parallel steps are successful' do
      plan = aggregate do
        task :A
        task :B
        success do
          serial do
            task :C
          end
        end
      end
      expect(plan.next).to eq %i[A B]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq [:C]
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::RUNNING
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS],
                         'C' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS],
                          'C' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end
  end

  context 'when a finally step is specified' do
    it 'always runs no matter the state for serial' do
      plan = serial do
        task :A
        finally do
          serial do
            task :B
          end
        end
      end

      expect(plan.next).to eq [:A]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::FAILED],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end

    it 'always runs no matter the state for parallel' do
      plan = aggregate do
        task :A
        finally do
          serial do
            task :B
          end
        end
      end

      expect(plan.next).to eq [:A]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::FAILED],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end
  end

  context 'the order precedence for success/failure and finally' do
    it 'recommends success/failure before finally in serial' do
      plan = serial do
        task :A
        success { serial { task :B } }
        failure { serial { task :C } }
        finally { serial { task :D } }
      end

      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq [:D]
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:C]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'C' => [Station::Status::SUCCESS]
                       })).to eq [:D]
    end

    it 'recommends success/failure before finally in parallel' do
      plan = aggregate do
        task :A
        success { serial { task :B } }
        failure { serial { task :C } }
        finally { serial { task :D } }
      end

      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq [:D]
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:C]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'C' => [Station::Status::SUCCESS]
                       })).to eq [:D]
    end
  end

  context 'when defining a try statement' do
    it 'always returns success' do
      plan = serial do
        try { serial { task :A } }
        task :B
      end

      expect(plan.next).to eq [:A]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.state(current: { 'A' => [Station::Status::SUCCESS] })).to eq Station::Status::RUNNING
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:B]
      expect(plan.state(current: { 'A' => [Station::Status::FAILED] })).to eq Station::Status::RUNNING
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
      expect(plan.state(current: {
                          'A' => [Station::Status::FAILED],
                          'B' => [Station::Status::SUCCESS]
                        })).to eq Station::Status::SUCCESS
    end

    it 'works with parallel' do
      plan = aggregate do
        task :A
        try { aggregate { task :B } }
      end

      expect(plan.next).to eq %i[A B]
      expect(plan.state(current: {
                          'A' => [Station::Status::SUCCESS],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::SUCCESS
      expect(plan.state(current: {
                          'A' => [Station::Status::FAILED],
                          'B' => [Station::Status::FAILED]
                        })).to eq Station::Status::FAILED
    end
  end

  context 'when handling attempts' do
    it 'only reruns the tasks for parallel' do
      plan = aggregate(attempts: 2) do
        task :A
        task :B
        failure { serial { task :C } }
      end

      expect(plan.next).to eq %i[A B]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq %i[A B]
      expect(plan.next(current: {
                         'A' => [Station::Status::FAILED],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq %i[A B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::FAILED],
                         'B' => [Station::Status::FAILED]
                       })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq [:B]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED, Station::Status::FAILED]
                       })).to eq [:C]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED, Station::Status::SUCCESS]
                       })).to eq []
    end

    it 'only reruns the tasks for serial' do
      plan = serial(attempts: 2) do
        task :A
        task :B
        failure { serial { task :C } }
      end

      expect(plan.next).to eq [:A]
      expect(plan.next(current: { 'A' => [Station::Status::SUCCESS] })).to eq [:B]
      expect(plan.next(current: { 'A' => [Station::Status::FAILED] })).to eq [:A]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED]
                       })).to eq [:A]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS],
                         'B' => [Station::Status::SUCCESS]
                       })).to eq []
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::FAILED],
                         'B' => [Station::Status::FAILED]
                       })).to eq [:C]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED, Station::Status::FAILED]
                       })).to eq [:C]
      expect(plan.next(current: {
                         'A' => [Station::Status::SUCCESS, Station::Status::SUCCESS],
                         'B' => [Station::Status::FAILED, Station::Status::SUCCESS]
                       })).to eq []
    end
  end
end

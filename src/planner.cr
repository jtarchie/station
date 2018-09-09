module Station
  module Planner
    alias Step = Task | Parallel | Serial | Try | Noop

    module Plan
      property success : Step = Noop.new
      property failure : Step = Noop.new
      property finally : Step = Noop.new

      def initialize(@attempts : Int32 = 1)
        @steps = [] of Step
      end

      def task(name)
        @steps.push Task.new(name.to_s)
      end

      def success(&block)
        plan = Actionable.new
        @success = with plan yield
      end

      def failure(&block)
        plan = Actionable.new
        @failure = with plan yield
      end

      def finally(&block)
        plan = Actionable.new
        @finally = with plan yield
      end

      def try(&block)
        plan = Try.new
        with plan yield
        @steps.push plan
      end

      def serial(attempts = 1, &block)
        plan = Serial.new(attempts)
        with plan yield
        @steps.push plan
      end

      def aggregate(attempts = 1, &block)
        plan = Parallel.new(attempts)
        with plan yield
        @steps.push plan
      end

      def state(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Status
        s = [
          plan_state(current, attempt),
          @success.state(current, attempt),
          @finally.state(current, attempt),
        ].compact.uniq
        return s.first if s.size == 1
        return Status::Failed if s.includes?(Status::Failed)
        return Status::Running
      end
    end

    class Task
      def initialize(name : String)
        @name = name
      end

      def next(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Array(String)
        return [] of String if current.has_key?(@name) && current[@name].size >= attempt
        [@name]
      end

      def state(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Status
        current.fetch(@name, [] of Status)[attempt - 1] rescue Status::Unstarted
      end
    end

    class Parallel
      include Plan

      def next(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Array(String)
        steps = [] of String

        1.step(to: @attempts).each do |actual|
          steps = @steps.map do |task|
            task.next(current, actual)
          end.flatten
          attempt = actual
          return steps if steps.size > 0
          next if steps.size == 0
        end

        steps += @success.next(current, attempt) if plan_state(current, attempt) == Status::Success
        steps += @failure.next(current, attempt) if plan_state(current, attempt) == Status::Failed
        steps += @finally.next(current, attempt) if steps.size == 0
        return steps
      end

      private def plan_state(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Status
        s = @steps.map do |step|
          step.state(current, attempt)
        end.compact.uniq!
        return s[0] if s.size == 1
        return Status::Running if s.includes?(Status::Unstarted)
        return Status::Running if s.includes?(Status::Running)
        return Status::Failed if s.includes?(Status::Failed)
        return Status::Running
      end
    end

    class Serial
      include Plan

      def next(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Array(String)
        steps = [] of Array(String)
        failed = false

        1.step(to: @attempts).each do |actual|
          @steps.each do |step|
            case step.state(current, actual)
            when Status::Success
              next
            when Status::Failed
              failed = true
              steps.clear
              break
            else
              steps << step.next(current, actual)
            end
          end
          attempt = actual
          break if steps.size == 0 && !failed
          break if steps.size > 0
        end
        steps += @success.next(current, attempt) if plan_state(current, attempt) == Status::Success
        steps += @failure.next(current, attempt) if plan_state(current, attempt) == Status::Failed
        steps += @finally.next(current, attempt)
        steps[0, 1].flatten
      end

      private def plan_state(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Status
        s = @steps.map do |step|
          step.state(current, attempt)
        end.compact.uniq!
        return s[0] if s.size == 1
        return Status::Failed if s.includes?(Status::Failed)
        return Status::Running
      end
    end

    module DSL
      def serial(attempts = 1, &block) : Serial
        plan = Serial.new(attempts)
        with plan yield
        plan
      end

      def aggregate(attempts = 1, &block) : Parallel
        plan = Parallel.new(attempts)
        with plan yield
        plan
      end
    end

    class Actionable
      include DSL
    end

    class Try
      include Plan

      def next(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Array(String)
        @steps.first.next(current, attempt)
      end

      def state(
        current : Hash(String, Array(Status)) = {} of String => Array(Status),
        attempt = 1
      ) : Status
        s = @steps.first.state(current, attempt)
        return Status::Success if s == Status::Failed
        return s || Status::Success
      end
    end

    class Noop
      def next(current, attempt = 1)
        [] of String
      end

      def state(current, attempt = 1)
        nil
      end
    end
  end
end

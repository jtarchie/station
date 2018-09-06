module Station
  module Planner
    alias Step = Task | Parallel | Serial | Noop

    module Plan
      property success : Step = Noop.new
      property failure : Step = Noop.new

      def initialize
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

      def serial(&block)
        plan = Serial.new
        with plan yield
        @steps.push plan
      end

      def aggregate(&block)
        plan = Parallel.new
        with plan yield
        @steps.push plan
      end

      def state(current : Hash(String, Status) = {} of String => Status) : Status
        s = [
          plan_state(current),
          @success.state(current),
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

      def next(current : Hash(String, Status) = {} of String => Status) : Array(String)
        return [] of String if current.has_key?(@name)
        [@name]
      end

      def state(current : Hash(String, Status) = {} of String => Status) : Status
        current.fetch(@name, Status::Unstarted)
      end
    end

    class Parallel
      include Plan

      def next(current : Hash(String, Status) = {} of String => Status) : Array(String)
        return @success.next(current) if plan_state(current) == Status::Success
        return @failure.next(current) if plan_state(current) == Status::Failed

        @steps.map do |task|
          task.next(current)
        end.flatten
      end

      private def plan_state(current : Hash(String, Status) = {} of String => Status) : Status
        s = @steps.map do |step|
          step.state(current)
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

      def next(current : Hash(String, Status) = {} of String => Status) : Array(String)
        return @success.next(current) if plan_state(current) == Status::Success
        return @failure.next(current) if plan_state(current) == Status::Failed

        steps = [] of Array(String)

        @steps.each do |step|
          case step.state(current)
          when Status::Success
            next
          when Status::Failed
            steps.clear
            break
          else
            steps << step.next(current)
          end
        end
        return steps[0, 1].flatten unless steps.empty?
        [] of String
      end

      private def plan_state(current : Hash(String, Status) = {} of String => Status) : Status
        s = @steps.map do |step|
          step.state(current)
        end.compact.uniq!
        return s[0] if s.size == 1
        return Status::Failed if s.includes?(Status::Failed)
        return Status::Running
      end
    end

    module DSL
      def serial(&block) : Serial
        plan = Serial.new
        with plan yield
        plan
      end

      def aggregate(&block) : Parallel
        plan = Parallel.new
        with plan yield
        plan
      end
    end

    class Actionable
      include DSL
    end

    class Noop
      def next(current)
        [] of String
      end

      def state(current)
        nil
      end
    end
  end
end

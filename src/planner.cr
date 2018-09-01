module Station
  module Planner
    alias Step = Task | Parallel | Serial

    module Plan
      def initialize
        @steps = [] of Step
      end

      def task(name)
        @steps.push Task.new(name.to_s)
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
        @steps.map do |task|
          task.next(current)
        end.flatten
      end

      def state(current : Hash(String, Status) = {} of String => Status) : Status
        s = @steps.map do |step|
          step.state(current)
        end.uniq!
        return s[0] if s.size == 1
        return Status::Running if s.includes?(Status::Running)
        return Status::Failed if s.includes?(Status::Failed)
        return Status::Running
      end
    end

    class Serial
      include Plan

      def next(current : Hash(String, Status) = {} of String => Status) : Array(String)
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

      def state(current : Hash(String, Status) = {} of String => Status) : Status
        s = @steps.map do |step|
          step.state(current)
        end.uniq!
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
  end
end

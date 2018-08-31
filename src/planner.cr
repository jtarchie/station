module Station
  module Planner
    alias Step = Task | Parallel | Serial

    module Plan
      def initialize
        @steps = [] of Step
      end

      def state(current = nil) : Status
        return current[1] if current
        return Status::Unstarted
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

      def next : Array(String)
        [ @name ]
      end
    end

    class Parallel
      include Plan

      def next(current = nil) : Array(String)
        return [] of String if current

        @steps.map do |task|
          task.next
        end.flatten
      end
    end

    class Serial
      include Plan

      def next(current = nil) : Array(String)
        return [] of String if current
        @steps[0].next
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

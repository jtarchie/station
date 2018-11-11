# frozen_string_literal: true

module Station
  module Planner
    module Plan
      def initialize(attempts: 1)
        @attempts = attempts
        @steps = []
      end

      def task(ref)
        @steps.push Task.new(name: ref.to_s, ref: ref)
      end

      def success(&block)
        @success ||= Noop.new
        if block_given?
          plan = Actionable.new
          @success = plan.instance_eval(&block)
        end
        @success
      end

      def failure(&block)
        @failure ||= Noop.new
        if block_given?
          plan = Actionable.new
          @failure = plan.instance_eval(&block)
        end
        @failure
      end

      def finally(&block)
        @finally ||= Noop.new
        if block_given?
          plan = Actionable.new
          @finally = plan.instance_eval(&block)
        end
        @finally
      end

      def try(&block)
        plan = Try.new
        plan.instance_eval(&block)
        @steps.push plan
      end

      def serial(attempts: 1, &block)
        plan = Serial.new(attempts: attempts)
        plan.instance_eval(&block)
        @steps.push plan
      end

      def aggregate(attempts: 1, &block)
        plan = Parallel.new(attempts: attempts)
        plan.instance_eval(&block)
        @steps.push plan
      end

      def state(
        current: {},
        attempt: 1
      )
        s = [
          plan_state(current: current, attempt: attempt),
          success.state(current: current, attempt: attempt),
          finally.state(current: current, attempt: attempt)
        ].compact.uniq

        return s.first if s.size == 1
        return Status::Failed if s.include?(Status::Failed)

        Status::Running
      end
    end

    Task = Struct.new(:name, :ref, keyword_init: true) do
      def next(
        current: {},
        attempt: 1
      )
        return [] if current.key?(name) && current[name].size >= attempt

        [ref]
      end

      def state(
        current: {},
        attempt: 1
      )

        current.fetch(name, []).fetch(attempt - 1)
      rescue IndexError
        Status::Unstarted
      end
    end

    class Parallel
      include Plan

      def next(
        current: {},
        attempt: 1
      )
        steps = []

        1.step(@attempts).each do |actual|
          steps = @steps.map do |task|
            task.next(current: current, attempt: actual)
          end.flatten
          attempt = actual
          return steps unless steps.empty?
          next if steps.empty?
        end

        steps += success.next(current: current, attempt: attempt) if plan_state(current: current, attempt: attempt) == Status::Success
        steps += failure.next(current: current, attempt: attempt) if plan_state(current: current, attempt: attempt) == Status::Failed
        steps += finally.next(current: current, attempt: attempt) if steps.empty?
        steps
      end

      private

      def plan_state(
        current: {},
        attempt: 1
      )
        s = @steps.map do |step|
          step.state(current: current, attempt: attempt)
        end.compact.uniq
        return s[0] if s.size == 1
        return Status::Running if s.include?(Status::Unstarted)
        return Status::Running if s.include?(Status::Running)
        return Status::Failed if s.include?(Status::Failed)

        Status::Running
      end
    end

    class Serial
      include Plan

      def next(
        current: {},
        attempt: 1
      )
        steps = []
        failed = false

        1.step(@attempts).each do |actual|
          @steps.each do |step|
            case step.state(current: current, attempt: actual)
            when Status::Success
              next
            when Status::Failed
              failed = true
              steps.clear
              break
            else
              steps << step.next(current: current, attempt: actual)
            end
          end
          attempt = actual
          break if steps.empty? && !failed
          break unless steps.empty?
        end
        steps += success.next(current: current, attempt: attempt) if plan_state(current: current, attempt: attempt) == Status::Success
        steps += failure.next(current: current, attempt: attempt) if plan_state(current: current, attempt: attempt) == Status::Failed
        steps += finally.next(current: current, attempt: attempt)
        steps[0, 1].flatten
      end

      private

      def plan_state(
        current: {},
        attempt: 1
      )
        s = @steps.map do |step|
          step.state(current: current, attempt: attempt)
        end.compact.uniq
        return s[0] if s.size == 1
        return Status::Failed if s.include?(Status::Failed)

        Status::Running
      end
    end

    module DSL
      def serial(attempts: 1, &block)
        plan = Serial.new(attempts: attempts)
        plan.instance_eval(&block)
        plan
      end

      def aggregate(attempts: 1, &block)
        plan = Parallel.new(attempts: attempts)
        plan.instance_eval(&block)
        plan
      end
    end

    class Actionable
      include DSL
    end

    class Try
      include Plan

      def next(
        current: {},
        attempt: 1
      )
        @steps.first.next(current: current, attempt: attempt)
      end

      def state(
        current: {},
        attempt: 1
      )
        s = @steps.first.state(current: current, attempt: attempt)
        return Status::Success if s == Status::Failed

        s || Status::Success
      end
    end

    class Noop
      def next(*)
        []
      end

      def state(*)
        nil
      end
    end
  end
end

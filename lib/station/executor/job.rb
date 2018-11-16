# frozen_string_literal: true

module Station
  module Executor
    class Job
      def initialize(plan:, volumes:, versions:)
        @plan = plan
        @volumes = volumes
        @versions = versions
      end

      def perform!
        results = Hash.new { |hash, key| hash[key] = [] }
        steps = @plan.next(current: results)
        until steps.empty?
          steps.each do |step|
            case step
            when Station::Actions::CheckResource
              peform_check(results, step)
            when Station::Actions::GetResource
              peform_get(results, step)
            when Station::Actions::PutResource
              peform_put(results, step)
            else
              raise "unsupported step to execute: #{step.inspect}"
            end
          end
          steps = @plan.next(current: results)
        end
        results
      end

      private

      def peform_put(results, step)
        result = step.perform!(
          mounts_dir: @volumes[step.resource.name]
        )
        results[step.to_s] = [result.status]
      end

      def peform_get(results, step)
        result = step.perform!(
          version: @versions[step.resource.name].last,
          destination_dir: @volumes[step.resource.name]
        )
        results[step.to_s] = [result.status]
      end

      def peform_check(results, step)
        result = step.perform!
        @versions[step.resource.name] += result.payload
        results[step.to_s] = [result.status]
      end
    end
  end
end

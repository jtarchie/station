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
              result = step.perform!
              @versions[step.resource.name] += result.payload
              results[step.to_s] = [result.status]
            when Station::Actions::GetResource
              result = step.perform!(
                version: @versions[step.resource.name].last,
                destination_dir: @volumes[step.resource.name]
              )
              results[step.to_s] = [result.status]
            when Station::Actions::PutResource
              result = step.perform!(
                mounts_dir: @volumes[step.resource.name]
              )
              results[step.to_s] = [result.status]
            else
              raise "unsupported step to execute: #{step.inspect}"
            end
          end
          steps = @plan.next(current: results)
        end
        results
      end
    end
end
end

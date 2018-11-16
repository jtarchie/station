# frozen_string_literal: true

module Station
  class Builder
    include Station::Planner::DSL

    def initialize(pipeline:)
      @pipeline = pipeline
    end

    def plans
      plans = {}
      @pipeline.jobs.each do |job|
        plans[job.name] = Station::Planner::Serial.new(steps: plans_for_steps(job.plan))
      end
      plans
    end

    private

    def plans_for_steps(steps)
      plans = steps.map do |step|
        case step
        when Station::Pipeline::Job::Get
          plan_for_get(step)
        when Station::Pipeline::Job::Put
          plan_for_put(step)
        when Station::Pipeline::Job::Do
          plan_for_do(step)
        when Station::Pipeline::Job::Try
          plan_for_try(step)
        when Station::Pipeline::Job::Aggregate
          plan_for_aggregate(step)
        else
          raise "don't support '#{step.class}' as a feature, yet"
        end
      end
    end

    def plan_for_try(step)
      Station::Planner::Try.new(steps: plans_for_steps([step.try]).first)
    end

    def plan_for_do(step)
      Station::Planner::Serial.new(steps: plans_for_steps(step.do))
    end

    def plan_for_aggregate(step)
      Station::Planner::Parallel.new(steps: plans_for_steps(step.aggregate))
    end

    def plan_for_get(step)
      resource = @pipeline.resources.find { |r| r.name == step.resource_name }
      serial do
        task Station::Actions::CheckResource.new(resource: resource)
        task Station::Actions::GetResource.new(
          resource: resource,
          params: step.params
        )
      end
    end

    def plan_for_put(step)
      resource = @pipeline.resources.find { |r| r.name == step.resource_name }
      serial do
        task Station::Actions::PutResource.new(
          resource: resource,
          params: step.params
        )
      end
    end
  end
end

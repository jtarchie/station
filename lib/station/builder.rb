# frozen_string_literal: true

module Station
  class Builder
    include Station::Planner::DSL

    def initialize(pipeline:)
      @pipeline = pipeline
    end

    def plans
      plans = {}
      resources = @pipeline.resources
      @pipeline.jobs.each do |job|
        plans[job.name] = serial do
          job.plan.map do |step|
            case step
            when Station::Pipeline::Jobs::Get
              resource_name = step.resource || step.get
              resource = resources.find { |r| r.name == resource_name }
              serial do
                task Station::Actions::CheckResource.new(resource: resource)
                task Station::Actions::GetResource.new(
                  resource: resource,
                  params: step.params
                )
              end
            else
              raise "don't support this feature, yet"
            end
          end
        end
      end
      plans
    end
  end
end

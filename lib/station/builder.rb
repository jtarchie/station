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
        steps = job.plan.map do |step|
          plans[job.name] = case step
                            when Station::Pipeline::Jobs::Get
                              resource_name = step.get
                              resource = @pipeline.resources.find { |r| r.name == resource_name }
                              serial do
                                task Station::Actions::CheckResource.new(resource: resource)
                                task Station::Actions::GetResource.new(resource: resource)
                              end
                            else
                              raise "don't support this feature, yet"
          end
        end
      end
      plans
    end
  end
end

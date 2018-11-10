# frozen_string_literal: true

module Station
  class Pipeline < Mapping
    class Resource < Mapping
      property :name, String, required: true
      property :type, String, required: true
      property :source, Hash, default: -> { {} }
    end

    class ResourceTypes < Mapping
      property :name, String, required: true
      property :type, String, required: true
      property :source, Hash, default: -> { {} }
    end

    class Jobs < Mapping
      class Plan < Mapping
      end

      property :name, String, required: true
      property :plan, Plan, default: -> { [] }
    end

    collection :resources, Pipeline::Resource
    collection :jobs, Pipeline::Jobs
    collection :resource_types, Pipeline::ResourceTypes

    def self.from_yaml(payload)
      new(YAML.safe_load(payload))
    end
  end
end

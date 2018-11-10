# frozen_string_literal: true

module Station
  class Pipeline < Mapping
    class Resource < Mapping
      property :name, String, required: true
      property :type, String, required: true
      property :source, Hash(String, String), default: -> { {} }
      property :version, Hash(String, String), default: -> { {} }
      property :check_every, String, default: -> { '1m' }
      property :tags, Array(String), default: -> { [] }
      property :webhook_token, String
    end

    class ResourceTypes < Mapping
      property :name, String, required: true
      property :type, String, required: true
      property :source, Hash(String, String), default: -> { {} }
      property :privileged, boolean, default: -> { false }
      property :params, Hash(String, String), default: -> { {} }
      property :check_every, String, default: -> { '1m' }
      property :tags, Array(String), default: -> { [] }
    end

    class Jobs < Mapping
      class Step < Mapping
      end

      property :name, String, required: true
      property :plan, Array(Step), required: true
      property :serial, boolean, default: -> { false }
      property :build_logs_to_retain, Integer
      property :serial_groups, Array(String), default: -> { [] }
      property :max_in_flight, Integer
      property :public, boolean, default: -> { false }
      property :disable_manual_trigger, boolean, default: -> { false }
      property :interruptible, boolean, default: -> { false }
    end

    collection :resources, Pipeline::Resource
    collection :jobs, Pipeline::Jobs
    collection :resource_types, Pipeline::ResourceTypes

    def self.from_yaml(payload)
      new(YAML.safe_load(payload))
    end
  end
end

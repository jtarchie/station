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
      class Get < Mapping
        property :get, String, required: true
        property :resource, String
        property :version, Union(String, Hash(String, String))
        property :passed, Array(String)
        property :params, Hash(String, String)
        property :trigger, boolean, default: -> { false }
      end

      class Put < Mapping
        property :put, String, required: true
        property :resource, String
        property :params, Hash(String, String)
        property :get_params, Hash(String, String)
      end

      class Task < Mapping
        class Config < Mapping
          class ImageResource < Mapping
            property :type, String, required: true
            property :source, Hash(String, String), required: true
            property :params, Hash(String, String)
            property :version, Hash(String, String)
          end

          class Input < Mapping
            property :name, String, required: true
            property :path, String
            property :optional, boolean, default: -> { false }
          end

          class Output < Mapping
            property :name, String, required: true
            property :path, String
          end

          class Cache < Mapping
            property :path, String, required: true
          end

          class Run < Mapping
            property :path, String, required: true
            property :args, Array(String), default: -> { [] }
            property :dir, String
            property :user, String
          end

          property :platform, String, required: true
          property :image_resource, ImageResource
          property :params, Hash(String, String)
          property :run, Run
          collection :inputs, Input
          collection :outputs, Output
          collection :cached, Cache
        end

        property :task, String, required: true
        property :config, Config, required: true
        # property :file, String, required: true
        property :privileged, boolean, default: -> { false }
        property :params, Hash(String, String)
        property :image, String
        property :input_mapping, Hash(String, String)
        property :output_mapping, Hash(String, String)
      end

      Do = Class.new(Mapping)
      Try = Class.new(Mapping)
      Aggregate = Class.new(Mapping)
      Step = Union(Get, Put, Task, Do, Try, Aggregate)

      base = -> (klass) do
        klass.property :on_success, Step
        klass.property :on_failure, Step
        klass.property :on_abort, Step
        klass.property :ensure, Step
        klass.property :tags, Array(String)
        klass.property :timeout, String
        klass.property :attempts, Integer
      end

      base.(Task)
      base.(Put)
      base.(Get)
      base.(Do)
      base.(Aggregate)
      base.(Try)

      class Do < Mapping
        collection :do, Step, default: -> { [] }
      end

      class Aggregate < Mapping
        collection :aggregate, Step, default: -> { [] }
      end

      class Try < Mapping
        property :try, Step
      end

      property :name, String, required: true
      property :serial, boolean, default: -> { false }
      property :build_logs_to_retain, Integer
      property :serial_groups, Array(String), default: -> { [] }
      property :max_in_flight, Integer
      property :public, boolean, default: -> { false }
      property :disable_manual_trigger, boolean, default: -> { false }
      property :interruptible, boolean, default: -> { false }
      collection :plan, Step, required: true
    end

    collection :resources, Pipeline::Resource
    collection :jobs, Pipeline::Jobs
    collection :resource_types, Pipeline::ResourceTypes

    def self.from_yaml(payload)
      new(YAML.safe_load(payload))
    end
  end
end

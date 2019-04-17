frozen_string_literal: true

require 'json'

module Station
  module Actions
    class TriggerResource
      Result = Struct.new(:stderr, :status, keyword_init: true)

      def initialize(
        resource:,
        passed:,
      )
        @resource     = resource
        @passed       = passed
      end

      def perform!(versions:)
        version = versions.find_latest(
          resource_name: @resource.name,
          jobs: @passed
        )

        if version
          success
        end

        wait
      end
    end
  end
end
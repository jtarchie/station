# frozen_string_literal: true

module Station
  module Actions
    class Task
      Result = Struct.new(:stdout, :stderr, :status, keyword_init: true)

      def initialize(config:, runner_klass: Station::Runner::Docker)
        @config = config
        @runner_klass = runner_klass
      end

      def perform!(volumes:)
        @config.inputs.each do |input|
          next if input.optional

          volume = volumes.find { |v| v.to == input.path }
          unless volume
            return Result.new(
              status: Station::Status::ERROR
            )
          end
        end

        runner = @runner_klass.new(
          volumes: volumes,
          working_dir: File.join('/tmp/build/task', @config.run.dir),
          image: [@config.image_resource.source['repository'], @config.image_resource.source['tag']].join(':'),
          command: [@config.run.path] + @config.run.args,
          user: @config.run.user,
          env: @config.params
        )
        runner.execute!(payload: nil)
        result(runner)
      end

      private

      def result(runner)
        Result.new(
          stdout: runner.stdout,
          stderr: runner.stderr,
          status: runner.status == 0 ? Station::Status::SUCCESS : Station::Status::FAILED
        )
      end
    end
  end
end

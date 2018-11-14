# frozen_string_literal: true

require 'json'
require 'shellwords'
require 'open3'
require 'json'

module Station
  module Runner
    class Docker
      def initialize(
          volumes:,
          working_dir:,
          image:,
          command:,
          stdout: StringIO.new,
          stderr: StringIO.new
        )
        @volumes = volumes
        @working_dir = working_dir
        @image = image
        @command = command
        @stderr = stderr
        @stdout = stdout
      end

      def stdout
        @stdout.string
      end

      def stderr
        @stderr.string
      end

      attr_reader :status

      def execute!(payload:)
        Open3.popen3(args.shelljoin) do |stdin, stdout, stderr, wait_thr|
          write_stdin(payload, stdin)

          read(stderr, stdout, wait_thr)
          @status = wait_thr.value.exitstatus
        end
      end

      private

      def read(stderr, stdout, wait_thr)
        readers = [stdout, stderr]

        while !!wait_thr.status
          next if readers.empty?

          reader = IO.select(readers)[0][0]
          begin
            output = reader.read_nonblock(1024)
            print output if ENV['DEBUG']
            case reader
            when stdout then @stdout.write output
            when stderr then @stderr.write output
            end
          rescue EOFError
            readers.delete(reader)
          end
        end
      end

      def write_stdin(payload, stdin)
        puts "stdin: #{payload.to_json}" if ENV['DEBUG']
        stdin.write(payload.to_json)
        stdin.close
      end

      def args
        args = ['docker', 'run', '-i', '--rm', '--privileged=false']
        @volumes.each do |volume|
          args += ['-v', "#{volume.from}:#{volume.to}"]
        end
        args += ['-w', @working_dir]
        args += [@image]
        args += @command
      end
    end
  end
end

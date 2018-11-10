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

      def execute!(payload:)
        args = ['docker', 'run', '-i', '--rm', '--privileged=false']
        @volumes.each do |volume|
          args += ['-v', "#{volume.from}:#{volume.to}"]
        end
        args += ['-w', @working_dir]
        args += [@image]
        args += @command
        Open3.popen3(args.shelljoin) do |stdin, stdout, stderr, wait_thr|
          puts "stdin: #{payload.to_json}" if ENV['DEBUG']
          stdin.write(payload.to_json)
          stdin.close

          readers = [stdout, stderr]

          while !!wait_thr.status
            next if readers.empty?

            reader = IO.select(readers)[0][0]
            begin
              output = reader.read_nonblock(1024)
              print output if ENV['DEBUG']
              @stdout.write output if reader == stdout
              @stderr.write output if reader == stderr
            rescue EOFError
              readers.delete(reader)
            end
          end
        end
      end
    end
  end
end

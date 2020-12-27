# frozen_string_literal: true

module Hrb
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      command, *files = @argv
      case command
      when "watch"
        Watcher.new(files).watch
      when "build"
        content = File.read(files.first)

        puts Program.new(content).output
      when "init"
        Initializer.new
      else
        abort "Hrb doesn't know how to #{command}"
      end
    end
  end
end

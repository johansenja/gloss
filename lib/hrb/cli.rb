# frozen_string_literal: true

require "optparse"

module Hrb
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      command, *files = @argv
      case command
      when "watch"
        Watcher.new.watch
      when "build"
        content = File.read(files.first)

        Writer.new(Builder.new(content).run,
                   files.first)
      when "init"
        force = false
        OptionParser.new do |opt|
          opt.on("--force", "-f") { force = true }
        end.parse(@argv)
        Initializer.new(force).run
      else
        abort "Hrb doesn't know how to #{command}"
      end
    end
  end
end

# frozen_string_literal: true

require "optparse"

module Gloss
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
        (files.empty? ? Dir.glob("#{Config.src_dir}/**/*.rb") : files).each do |fp|
          puts "=====> Building #{fp}"
          content = File.read(fp)

          puts "=====> Writing #{fp}"
          Writer.new(Builder.new(content).run, fp).run
        end
      when "init"
        force = false
        OptionParser.new do |opt|
          opt.on("--force", "-f") { force = true }
        end.parse(@argv)
        Initializer.new(force).run
      else
        abort "Gloss doesn't know how to #{command}"
      end
    end
  end
end

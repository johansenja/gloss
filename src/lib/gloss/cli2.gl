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
        (files.empty? ? Dir.glob("#{Config.src_dir}/**/*.gl") : files).each do |fp|
          puts "=====> Building #{fp}"
          content = File.read(fp)
          tree_hash = Parser.new(content).run
          type_checker = TypeChecker.new
          rb_output = Builder.new(tree_hash, type_checker).run

          puts "=====> Writing #{fp}"
          Writer.new(rb_output, fp).run
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

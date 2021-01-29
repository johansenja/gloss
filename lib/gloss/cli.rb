# frozen_string_literal: true

##### This file was generated by Gloss; any changes made here will be overwritten.
##### See src/ to make changes

require "optparse"
module Gloss
  class CLI
    def initialize(argv)
      @argv = argv
    end
    def run()
      command = @argv.first
      files = @argv.[]((1..-1))
case command
        when "watch"
          Watcher.new
.watch
        when "build"
          (if files.empty?
            Dir.glob("#{Config.src_dir}/**/*.gl")
          else
            files
          end)
.each() { |fp|
            puts("=====> Building #{fp}")
            content = File.read(fp)
            tree_hash = Parser.new(content)
.run
            type_checker = TypeChecker.new
            rb_output = Builder.new(tree_hash, type_checker)
.run
            type_checker.run(rb_output)
            puts("=====> Writing #{fp}")
            Writer.new(rb_output, fp)
.run
          }
        when "init"
          force = false
          OptionParser.new() { |opt|
            opt.on("--force", "-f") { ||
              force = true
            }
          }
.parse(@argv)
          Initializer.new(force)
.run
      end
    end
  end
end


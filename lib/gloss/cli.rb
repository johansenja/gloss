  
  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See / to make changes

require "optparse"
module Gloss
  class CLI
    def initialize(argv)
      @argv = argv
    end
    def run()
      command = @argv.first
      files = @argv.[](((1)..(-1)))
      err_msg = catch(:"error") { ||
case command
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
          when "version", "--version", "-v"
            puts(Gloss::VERSION)
          when "watch", "build"
            Gloss.load_config
            type_checker = ProgLoader.new
.run
            (if command.==("watch")
              files = files.map() { |f|
                path = (if Pathname.new(f)
.absolute?
                  f
                else
                  File.join(Dir.pwd, f)
                end)
                (if Pathname.new(path)
.exist?
                  path
                else
                  throw(:"error", "Pathname #{f} does not exist")
                end)
              }
              Watcher.new(files)
.watch
            else
              (if command.==("build")
                entry_tree = Parser.new(File.read(Config.entrypoint))
.run
                Visitor.new(entry_tree, type_checker)
.run
                (if files.empty?
                  files = Dir.glob("#{Config.src_dir}/**/*.gl")
                end)
                files.each() { |fp|
                  fp = File.absolute_path(fp)
                  preloaded_output = OUTPUT_BY_PATH.fetch(fp) { ||
nil                  }
                  (if preloaded_output
                    rb_output = preloaded_output
                  else
                    Gloss.logger
.info("Building #{fp}")
                    content = File.read(fp)
                    tree_hash = Parser.new(content)
.run
                    rb_output = Visitor.new(tree_hash, type_checker)
.run
                  end)
                  Gloss.logger
.info("Type checking #{fp}")
                  type_checker.run(fp, rb_output)
                }
                files.each() { |fp|
                  fp = File.absolute_path(fp)
                  rb_output = OUTPUT_BY_PATH.fetch(fp)
                  Gloss.logger
.info("Writing #{fp}")
                  Writer.new(rb_output, fp)
.run
                }
              end)
            end)
          else
            throw(:"error", "Gloss doesn't know how to #{command}")
        end
nil      }
      (if err_msg
        abort(err_msg)
      end)
    end
  end
end

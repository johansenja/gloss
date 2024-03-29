  
  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See / to make changes

require "listen"
module Gloss
  class Watcher
    # @type var @listener: Listen?
    @listener
    def initialize(paths)
      @paths = paths
      (if @paths.empty?
        @paths = [File.join(Dir.pwd, Config.src_dir)]
        @only = /(?:(\.gl|(?:(?<=\/)[^\.\/]+))\z|\A[^\.\/]+\z)/
      else
        file_names = Array.new
        paths = Array.new
        @paths.each() { |pa|
          pn = Pathname.new(pa)
          paths.<<(pn.parent
.to_s)
          file_names.<<((if pn.file?
            pn.basename
.to_s
          else
            pa
          end))
        }
        @paths = paths.uniq
        @only = /#{Regexp.union(file_names)}/
      end)
    end
    def watch()
      Gloss.logger
.info("Now listening for changes in #{@paths.join(", ")}")
      @listener ||= Listen.to(*@paths, latency: 2, only: @only) { |modified, added, removed|
        modified.+(added)
.each() { |f|
          Gloss.logger
.info("Rewriting #{f}")
          content = File.read(f)
          err = catch(:"error") { ||
            Writer.new(Visitor.new(Parser.new(content)
.run)
.run, f)
.run
nil          }
          (if err
            Gloss.logger
.error(err)
          else
            Gloss.logger
.info("Done")
          end)
        }
        removed.each() { |f|
          out_path = Utils.src_path_to_output_path(f)
          Gloss.logger
.info("Removing #{out_path}")
          (if File.exist?(out_path)
            File.delete(out_path)
          end)
          Gloss.logger
.info("Done")
        }
      }
      begin
        @listener.start
        sleep
      rescue Interrupt
        kill
      end
    end
    def kill()
      Gloss.logger
.info("Interrupt signal received, shutting down")
      (if @listener
        @listener.stop
      end)
    end
  end
end

  
  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See / to make changes

require "rubygems/gem_runner"
module Gloss
  OUTPUT_BY_PATH = Hash.new
  class ProgLoader
    attr_reader(:"type_checker")
    def initialize(type_checker, entrypoint_path = nil, entrypoint_contents = nil)
      @type_checker = type_checker
      entrypoint_path ||= Config.entrypoint
      (if entrypoint_path.==(nil) || entrypoint_path.==("")
        throw(:"error", "Entrypoint is not yet set in .gloss.yml")
      end)
      entrypoint = (if entrypoint_path && entrypoint_contents
        ep = (if entrypoint_path.==(Runtime::NON_EXISTENT_FILEPATH)
          entrypoint_path
        else
          Utils.absolute_path(entrypoint_path)
        end)
[ep, entrypoint_contents]
      else
        Utils.abs_path_with_contents(entrypoint_path)
      end)
      core_types = Utils.abs_path_with_contents(File.join(__dir__ || "", "..", "..", "sig", "core.rbs"))
      @files_to_process = [entrypoint, core_types]
      @processed_files = Set.new
    end
    def run()
      @files_to_process.each() { |__arg0|
        path_string = __arg0.[](0)
        file_contents = __arg0.[](1)
        (if path_string.end_with?(".rbs")
          @type_checker.load_sig_path(path_string)
        else
          (if !@processed_files.member?(path_string) || !OUTPUT_BY_PATH.[](path_string)
            Gloss.logger
.debug("Loading #{path_string}")
            contents_tree = Parser.new(file_contents)
.run
            on_new_file_referenced = proc() { |ps, relative|
              ps.each() { |pa|
                (if relative
                  handle_require_relative(pa, path_string)
                else
                  handle_require(pa)
                end)
              }
            }
            OUTPUT_BY_PATH.[]=(path_string, Visitor.new(contents_tree, @type_checker, on_new_file_referenced)
.run)
            @processed_files.add(path_string)
          end)
        end)
      }
@type_checker
    end
    STDLIB_TYPE_DEPENDENCIES = {"yaml" => ["pstore", "dbm"],
"rbs" => ["logger", "set", "tsort"],
"logger" => ["monitor"]}
    private     def handle_require(path)
      (if path.start_with?(".")
        base = File.join(Dir.pwd, path)
        fp = base.+(".gl")
        (if File.exist?(fp)
          @files_to_process.<<(Utils.abs_path_with_contents(fp))
        end)
return
      end)
      full = File.absolute_path("#{File.join(Config.src_dir, "lib", path)}.gl")
      pathn = Pathname.new(full)
      (if pathn.file?
        @files_to_process.<<(Utils.abs_path_with_contents(pathn.to_s))
      else
        pathn = Pathname.new("#{File.join(Dir.pwd, "sig", path)}.rbs")
        gem_path = Utils.gem_path_for(path)
        (if gem_path
          sig_files = Dir.glob(File.absolute_path(File.join(gem_path, "..", "sig", "**", "*.rbs")))
          (if sig_files.length
.positive?
            sig_files.each() { |fp|
              @type_checker.load_sig_path(fp)
            }
            @processed_files.add(path)
            rbs_type_deps = STDLIB_TYPE_DEPENDENCIES.fetch(path) { ||
nil            }
            (if rbs_type_deps
              rbs_type_deps.each() { |d|
                handle_require(d)
              }
            end)
return
          end)
        end)
        (if pathn.file?
          @type_checker.load_sig_path(pathn.to_s)
          @processed_files.add(pathn.to_s)
        else
          rbs_stdlib_dir = File.absolute_path(File.join(@type_checker.rbs_gem_dir, "..", "stdlib", path))
          (if Pathname.new(rbs_stdlib_dir)
.exist?
            load_rbs_from_require_path(path)
            rbs_type_deps = STDLIB_TYPE_DEPENDENCIES.fetch(path) { ||
nil            }
            (if rbs_type_deps
              rbs_type_deps.each() { |d|
                load_rbs_from_require_path(d)
              }
            end)
          else
            (if Config.strict_require
              throw(:"error", "Cannot resolve require path for #{path}")
            else
              Gloss.logger
.debug("No path found for #{path}")
            end)
          end)
        end)
      end)
    end
    private     def handle_require_relative(path, source_file)
      base = File.join(source_file, "..", path)
      # @type var pn: String?
      pn = nil
      exts = [".gl"].concat(Gem.suffixes)
      exts.each() { |ext|
        full = File.absolute_path(base.+(ext))
        (if File.exist?(full)
          pn = full
        end)
      }
      (if pn
        unless         @files_to_process.any?() { |__arg1|
          fp = __arg1.[](0)
          fp.==(pn)
        }
          @files_to_process.<<(Utils.abs_path_with_contents(pn))
        end
      else
        (if Config.strict_require
          throw(:"error", "Cannot resolve relative path for #{path}")
        else
          Gloss.logger
.debug("No path found for #{path}")
        end)
      end)
    end
    private     def rbs_stdlib_path_for(libr)
      File.absolute_path(File.join(@type_checker.rbs_gem_dir, "..", "stdlib", libr))
    end
    private     def load_rbs_from_require_path(path)
      Dir.glob(File.join(rbs_stdlib_path_for(path), "**", "*.rbs"))
.each() { |fp|
        @type_checker.load_sig_path(fp)
        @processed_files.add(fp)
      }
    end
  end
end

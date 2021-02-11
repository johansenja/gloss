module Gloss
  module Utils
    module_function

    def absolute_path(path)
      pn = Pathname.new(path)
      if pn.absolute?
        pn.to_s
      else
        ap = File.absolute_path path
        if File.exist? ap
          ap
        else
          throw :error, "File path #{path} does not exist (also looked for #{ap})"
        end
      end
    end
  end

  class ProgLoader
    include Utils

    def initialize
      entrypoint = Config.entrypoint
      if entrypoint.nil? || entrypoint == ""
        throw :error, "Entrypoint is not yet set in .gloss.yml"
      end
      @files_to_process = [absolute_path(Config.entrypoint)]
      @processed_files = Set.new
      @type_checker = TypeChecker.new
    end

    def run
      @files_to_process.each do |path_string|
        next if @processed_files.member? path_string

        Gloss.logger.debug "Loading #{path_string}"
        path = absolute_path(path_string)
        file_contents = File.open(path).read
        contents_tree = Parser.new(file_contents).run
        on_new_file_referenced = proc do |pa, relative|
          if relative
            handle_require_relative pa
          else
            handle_require pa
          end
        end
        Visitor.new(contents_tree, @type_checker, on_new_file_referenced).run
        @processed_files.add path_string
      end

      @type_checker
    end

    private

    STDLIB_TYPE_DEPENDENCIES = {
      "yaml" => %w[pstore dbm],
      "rbs" => %w[logger set tsort],
      "logger" => %w[monitor],
    }

    def handle_require(path)
      if path.start_with? "."
        base = File.join(Dir.pwd, path)
        fp = base + ".gl"
        if File.exist? fp
          @files_to_process << fp
        end
        return
      end

      # look for .gl file if the "require" refers to the lib directory of current project dir
      full = File.absolute_path("#{File.join(Config.src_dir, "lib", path)}.gl")
      pathn = Pathname.new full
      if pathn.file?
        @files_to_process << pathn.to_s
      else
        # no .gl file available - .rbs file available?
        # TODO: verify file is still actually requireable
        pathn = Pathname.new("#{File.join(Dir.pwd, "sig", path)}.rbs")
        gem_path = `gem which #{path}`.chomp rescue nil
        if gem_path
          sig_files = Dir.glob(File.absolute_path(File.join(gem_path, "..", "..", "sig", "**", "*.rbs")))
          if sig_files.length.positive?
            sig_files.each do |fp|
              @type_checker.load_sig_path fp
            end
            @processed_files.add path
            rbs_type_deps = STDLIB_TYPE_DEPENDENCIES.fetch(path) { nil }
            if rbs_type_deps
              rbs_type_deps.each { |d| handle_require d }
            end
            return
          end
        end

        if pathn.file?
          @type_checker.load_sig_path(pathn.to_s)
          @processed_files.add pathn.to_s
        else
          rbs_stdlib_dir = File.absolute_path(File.join(@type_checker.rbs_gem_dir, "..", "..", "stdlib", path))
          if Pathname.new(rbs_stdlib_dir).exist?
            load_rbs_from_require_path(path)
            rbs_type_deps = STDLIB_TYPE_DEPENDENCIES.fetch(path) { nil }
            if rbs_type_deps
              rbs_type_deps.each { |d| load_rbs_from_require_path d }
            end
          elsif Config.strict_require
            throw :error, "Cannot resolve require path for #{pa}"
          else
            Gloss.logger.debug "No path found for #{path}"
          end
        end
      end
    end

    def handle_require_relative(path)
      base = File.join(@filepath, "..", path)
      pn = nil
      Gem.suffixes.each do |ext|
        full = File.absolute_path(base + ext)
        pn = full if File.exist?(full)
      end

      if pn
        @files_to_process << pn unless @files_to_process.include? pn
      elsif Config.strict_require
        throw :error, "Cannot resolve require path for #{pa}"
      else
        Gloss.logger.debug "No path found for #{path}"
      end
    end

    def rbs_stdlib_path_for(lib)
      File.absolute_path(File.join(@type_checker.rbs_gem_dir, "..", "..", "stdlib", lib))
    end

    def load_rbs_from_require_path(path)
      Dir.glob(File.join(rbs_stdlib_path_for(path), "**", "*.rbs")).each do |fp|
        @type_checker.load_sig_path(fp)
        @processed_files.add fp
      end
    end
  end
end

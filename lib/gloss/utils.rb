  # frozen_string_literal: true

  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See src/ to make changes

require "rubygems"
module Gloss
  module Utils
    module_function
    def absolute_path(path)
      pn = Pathname.new(path)
      (if pn.absolute?
        pn.to_s
      else
        ap = File.absolute_path(path)
        (if File.exist?(ap)
          ap
        else
          throw(:"error", "File path #{path} does not exist (also looked for #{ap})")
        end)
      end)
    end
    def gem_path_for(gem_name)
      spec = Gem::Specification.find_by_path(gem_name)
      (if spec
        spec.full_require_paths
.first
      end)
    end
    def with_file_header(str)
      "#{Visitor::FILE_HEADER}\n\n#{str}"
    end
    def src_path_to_output_path(src_path)
      src_path.sub("#{Config.src_dir}/", "")
.sub(/\.gl$/, ".rb")
    end
  end
end

  # frozen_string_literal: true

  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See src/ to make changes

  require "pathname"
require "fileutils"
module Gloss
  module Utils
    module_function
    def src_path_to_output_path(src_path)
      src_path.sub("#{Config.src_dir}/", "")
.sub(/\.gl$/, ".rb")
    end
  end
  class Writer
    include Utils
    def initialize(content, src_path, output_path = Pathname.new(src_path_to_output_path(src_path)))
      @content = content
      @output_path = output_path
    end
    def run()
      unless       @output_path.parent
.exist?
        FileUtils.mkdir_p(@output_path.parent)
      end
      File.open(@output_path, "wb") { |file|
        file.puts(@content)
      }
    end
  end
end

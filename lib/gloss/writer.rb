# frozen_string_literal: true
require "pathname"
require "fileutils"
module Gloss
  module Utils
    module_function
    def src_path_to_output_path(src_path)
      src_path.sub(/\A(?:\.\/)?#{Config.src_dir}\/?/, "")
.sub(/\.gl$/, ".rb")
    end
  end
  class Writer
    include Utils
    def initialize(content, src_path, output_path =     Pathname.new(src_path_to_output_path(@src_path))
)
      @content = content
      @src_path = src_path
      @output_path = output_path
    end
    def run()
      unless @output_path.directory? || @output_path.parent
.exist?
        FileUtils.mkdir_p(@output_path)
      end
      File.open(op, "wb") { |file|
        file.<<(@content)
      }
    end
  end
end

# frozen_string_literal: true

module Gloss
  module Utils
    module_function

    def src_path_to_output_path(src_path)
      src_path.sub(%r{\A(?:\./)?#{Config.src_dir}/?}, "")
              .sub(/\.gl$/, ".rb")
    end
  end

  class Writer
    include Utils

    def initialize(content, src_path, output_path = nil)
      @content, @src_path = content, src_path
      @output_path = output_path || src_path_to_output_path(src_path)
    end

    def run
      File.open(@output_path, "wb") do |file|
        file << @content
      end
    end
  end
end

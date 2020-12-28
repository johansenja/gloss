# frozen_string_literal: true

module Hrb
  class Writer
    def initialize(content, src_path, run_path = nil)
      @content, @src_path = content, src_path
      @run_path = run_path || src_path.sub(%r{\A(?:\./)?#{Config.src_dir}/?}, "")
    end

    def run
      File.open(@run_path, "wb") do |file|
        file << content
      end
    end
  end
end

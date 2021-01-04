# frozen_string_literal: true

require "listen"

module Gloss
  class Watcher
    def initialize
      @paths = %w[src/]
    end

    def watch
      puts "=====> Now listening for changes in #{@paths.join(', ')}"
      listener = Listen.to(*@paths, latency: 2) do |modified, added, removed|
        (modified + added).each do |f|
          content = File.read(f)
          Writer.new(Builder.new(content).run, f).run
        end
        removed.each do |f|
          out_path = Utils.src_path_to_output_path(f)
          File.delete out_path if File.exist? out_path
        end
      end
      listener.start
      begin
        loop { sleep 10 }
      rescue Interrupt
        puts "=====> Interrupt signal received, shutting down"
        exit 0
      end
    end
  end
end

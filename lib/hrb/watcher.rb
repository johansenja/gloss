# frozen_string_literal: true

require "listen"

module Hrb
  class Watcher
    def initialize
      @paths = %w[src/]
    end

    def watch
      puts "=====> Now listening for changes in #{@paths.join(', ')}"
      listener = Listen.to(*@paths, latency: 2) do |modified, added, removed|
        p modified, added, removed
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

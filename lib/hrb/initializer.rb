# frozen_string_literal: true

require "yaml"

module Hrb
  class Initializer
    def initialize(force)
      @force = force
    end

    def run
      if File.exists? ".hrb.yml" and not @force
        abort ".hrb.yml file already exists - aborting. Use --force to override."
      end

      File.open(".hrb.yml", "wb") do |file|
        file.puts Config::DEFAULT.transform_keys(&:to_s).to_yaml
      end

      puts "Created .hrb.yml with default preferences"
    end
  end
end

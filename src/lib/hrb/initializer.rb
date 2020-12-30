# frozen_string_literal: true

require "yaml"

module Hrb
  class Initializer
    def initialize(@force)
    end

    def run
      if File.exist?(".hrb.yml") && !@force
        abort ".hrb.yml file already exists - aborting. Use --force to override."
      end

      File.open(".hrb.yml", "wb") do |file|
        file.puts Config.default_config.transform_keys(&:to_s).to_yaml
      end

      puts "Created .hrb.yml with default preferences"
    end
  end
end

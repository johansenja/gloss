# frozen_string_literal: true
require "yaml"
module Gloss
  class Initializer
    def initialize(force)
      @force = force
    end
    def run()
      (if File.exist?(".gloss.yml") && !@force
        abort(".gloss.yml file already exists - aborting. Use --force to override.")
      end)
      File.open(".gloss.yml", "wb") { |file|
        file.puts(Config.default_config
.transform_keys(&:to_s)
.to_yaml)
      }
      puts("Created .gloss.yml with default preferences")
    end
  end
end
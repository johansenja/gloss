  
  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See / to make changes

require "yaml"
module Gloss
  class Initializer
    def initialize(force)
      @force = force
    end
    def run()
      (if File.exist?(CONFIG_PATH) && !@force
        throw(:"error", "#{CONFIG_PATH} file already exists - aborting. Use --force to override.")
      end)
      File.open(CONFIG_PATH, "wb") { |file|
        file.puts(Config.default_config
.transform_keys(&:"to_s")
.to_yaml)
      }
      Gloss.logger
.info("Created #{CONFIG_PATH} with default preferences")
    end
  end
end

  # frozen_string_literal: true

  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See src/ to make changes

require "ostruct"
require "yaml"
module Gloss
  CONFIG_PATH = ".gloss.yml"
  Config = OpenStruct.new(default_config: {:frozen_string_literals => true,
:src_dir => "src", entrypoint: nil, strict_require: false}.freeze)
  user_config = (if File.exist?(CONFIG_PATH)
    YAML.safe_load(File.read(CONFIG_PATH))
  else
    Config.default_config
  end)
  Config.default_config
.each() { |k, v|
    Config.send(:"#{k}=", user_config.[](k.to_s) || v)
  }
end

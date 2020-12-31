# frozen_string_literal: true

require "ostruct"
require "yaml"

module Gloss
  user_config = YAML.safe_load(File.read(".gloss.yml"))
  Config = OpenStruct.new(
    default_config: {
      frozen_string_literals: true,
      src_dir: "src",
    }.freeze
  )
  Config.default_config.each { |k, v| Config.send(:"#{k}=", user_config[k.to_s] || v) }
end
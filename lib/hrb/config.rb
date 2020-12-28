# frozen_string_literal: true

module Hrb
  class Config
    DEFAULT = {
      frozen_string_literals: true,
      src_dir: "src",
    }.freeze

    attr_reader :config

    def initialize
      user_config = YAML.safe_load(File.read(".hrb.yml"))
      @config = DEFAULT.map { |k,v| user_config[k.to_s] || v }.to_h
    end
  end

  def self.Config
    @Config ||= Config.new.config
  end
end

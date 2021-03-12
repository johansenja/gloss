  # frozen_string_literal: true

  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See src/ to make changes

module Gloss
  def self.logger()
    (if @logger
      @logger
    else
      env_log_level = ENV.fetch("LOG_LEVEL") { ||
"INFO"      }
      real_log_level = {"UNKNOWN" => Logger::UNKNOWN,
"FATAL" => Logger::FATAL,
"ERROR" => Logger::ERROR,
"WARN" => Logger::WARN,
"INFO" => Logger::INFO,
"DEBUG" => Logger::DEBUG,
"NIL" => nil,
nil => nil,
"" => nil}.fetch(env_log_level)
      @logger = Logger.new((if real_log_level
        STDOUT
      else
        IO::NULL
      end))
.tap() { |l|
        (if real_log_level
          l.level=(real_log_level)
        end)
      }
    end)
  end
end

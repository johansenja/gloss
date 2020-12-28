# frozen_string_literal: true

require "rbs"
require "json"
require "steep"
require "fast_blank"

require "hrb/version"
require "hrb/cli"
require "hrb/watcher"
require "hrb/initializer"
require "hrb/config"
require "hrb/writer"
require "hrb/source"
require "hrb/scope"
require "hrb/builder"
require "hrb/errors"

require "hrb.bundle"

EMPTY_ARRAY = [].freeze
EMPTY_HASH = {}.freeze

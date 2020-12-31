# frozen_string_literal: true

require "rbs"
require "json"
require "steep"
require "fast_blank"

require "gloss/version"
require "gloss/cli"
require "gloss/watcher"
require "gloss/type_checker"
require "gloss/parser"
require "gloss/initializer"
require "gloss/config"
require "gloss/writer"
require "gloss/source"
require "gloss/scope"
require "gloss/builder"
require "gloss/errors"

require "gls"

EMPTY_ARRAY = [].freeze
EMPTY_HASH = {}.freeze

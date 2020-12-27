module Hrb
  module Errors
    class BaseHrbError < StandardError; end

    class TypeValidationError < BaseHrbError; end

    class TypeError < BaseHrbError; end

    class ParserError < BaseHrbError; end
  end
end

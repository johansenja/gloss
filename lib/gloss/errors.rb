module Gloss
  module Errors
    class BaseGlossError < StandardError; end

    class TypeValidationError < BaseGlossError; end

    class TypeError < BaseGlossError; end

    class ParserError < BaseGlossError; end
  end
end

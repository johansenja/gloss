# frozen_string_literal: true
module Gloss
  class Parser
    def initialize(str)
      @str = str
    end
    def run()
      tree_json = Gloss.parse_buffer(@str)
      begin
        JSON.parse(tree_json, symbolize_names: true)
      rescue JSON::ParserError
        raise(Errors::ParserError, tree_json)
      end
    end
  end
end

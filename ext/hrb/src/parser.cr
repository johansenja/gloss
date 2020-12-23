require "compiler/crystal/syntax/*"

module Hrb
  class Parser < Crystal::Parser
    def parse_empty_array_literal
      line = @line_number
      column = @token.column_number

      # next_token_skip_space
      # next_token_skip_space_or_newline
      # of = nil
      Crystal::ArrayLiteral.new([] of Crystal::ASTNode) # .at_end(of)
    end

    def new_hash_literal(entries, line, column, end_location, allow_of = true)
      of = nil

      if allow_of
        if @token.keyword?(:of)
          next_token_skip_space_or_newline
          of_key = parse_bare_proc_type
          check :"=>"
          next_token_skip_space_or_newline
          of_value = parse_bare_proc_type
          of = Crystal::HashLiteral::Entry.new(of_key, of_value)
          end_location = of_value.end_location
        end

        # if entries.empty? && !of
        #   raise "for empty hashes use '{} of KeyType => ValueType'", line, column
        # end
      end

      Crystal::HashLiteral.new(entries, of).at_end(end_location)
    end
  end
end

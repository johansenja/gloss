require "compiler/crystal/syntax/*"
require "./lexer"

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

    def parse_rescue
      next_token_skip_space

      if @token.type == :CONST || @token.type == :"::"
        types = parse_rescue_types
        skip_space
      end

      if @token.type == :"=>"
        next_token_skip_space
      end

      if @token.type == :IDENT
        name = @token.value.to_s
        push_var_name name
        next_token_skip_space
      end

      check SemicolonOrNewLine

      next_token_skip_space_or_newline

      if @token.keyword?(:end)
        body = nil
      else
        body = parse_expressions
        skip_statement_end
      end

      Crystal::Rescue.new(body, types, name)
    end

    def parse_rescue_types
      types = [] of Crystal::ASTNode
      while true
        types << parse_generic
        skip_space
        if @token.type == :","
          next_token_skip_space
        else
          skip_space
          break
        end
      end
      types
    end

    def parse_arg(args, extra_assigns, parentheses, found_default_value, found_splat, found_double_splat, allow_restrictions)
      if @token.type == :"&"
        next_token_skip_space_or_newline
        block_arg = parse_block_arg(extra_assigns)
        skip_space_or_newline
        # When block_arg.name is empty, this is an anonymous argument.
        # An anonymous argument should not conflict other arguments names.
        # (In fact `args` may contain anonymous splat argument. See #9108).
        # So check is skipped.
        unless block_arg.name.empty?
          conflict_arg = args.any?(&.name.==(block_arg.name))
          conflict_double_splat = found_double_splat && found_double_splat.name == block_arg.name
          if conflict_arg || conflict_double_splat
            raise "duplicated argument name: #{block_arg.name}", block_arg.location.not_nil!
          end
        end
        return ArgExtras.new(block_arg, false, false, false)
      end

      if found_double_splat
        raise "only block argument is allowed after double splat"
      end

      splat = false
      double_splat = false
      arg_location = @token.location
      allow_external_name = true

      case @token.type
      when :"*"
        if found_splat
          unexpected_token
        end

        splat = true
        allow_external_name = false
        next_token_skip_space
      when :"**"
        double_splat = true
        allow_external_name = false
        next_token_skip_space
      else
        # not a splat
      end

      found_space = false

      if splat && (@token.type == :"," || @token.type == :")")
        arg_name = ""
        uses_arg = false
        allow_restrictions = false
      else
        arg_location = @token.location
        arg_name, external_name, found_space, uses_arg = parse_arg_name(arg_location, extra_assigns, allow_external_name: allow_external_name)

        args.each do |arg|
          if arg.name == arg_name
            raise "duplicated argument name: #{arg_name}", arg_location
          end

          if arg.external_name == external_name
            raise "duplicated argument external name: #{external_name}", arg_location
          end
        end

        if @token.type == :SYMBOL
          raise "space required after colon in type restriction", @token
        end
      end

      default_value = nil
      restriction = nil
      keyword_argument = @token.type == :":" && !found_space

      found_colon = false

      next_token_skip_space

      if allow_restrictions && @token.type == :":"

        next_token_skip_space_or_newline

        location = @token.location
        splat_restriction = false
        if (splat && @token.type == :"*") || (double_splat && @token.type == :"**")
          splat_restriction = true
          next_token
        end

        restriction = parse_bare_proc_type

        if splat_restriction
          restriction = splat ? Crystal::Splat.new(restriction) : Crystal::DoubleSplat.new(restriction)
          restriction.at(location)
        end
        found_colon = true
      end

      if @token.type == :"="
        raise "splat argument can't have default value", @token if splat
        raise "double splat argument can't have default value", @token if double_splat

        slash_is_regex!
        next_token_skip_space_or_newline

        case @token.type
        when :__LINE__, :__END_LINE__, :__FILE__, :__DIR__
          default_value = Crystal::MagicConstant.new(@token.type).at(@token.location)
          next_token
        else
          @no_type_declaration += 1
          default_value = parse_op_assign
          @no_type_declaration -= 1
        end

        skip_space
      else
        if found_default_value && !found_splat && !splat && !double_splat
          raise "argument must have a default value", arg_location
        end
      end

      unless found_colon
        if @token.type == :SYMBOL
          raise "the syntax for an argument with a default value V and type T is `arg : T = V`", @token
        end

        if allow_restrictions && @token.type == :":"
          raise "the syntax for an argument with a default value V and type T is `arg : T = V`", @token
        end
      end

      raise "BUG: arg_name is nil" unless arg_name

      arg = Crystal::Arg.new(arg_name, default_value, restriction, external_name: external_name).at(arg_location)
      arg.keyword_arg = keyword_argument
      args << arg
      push_var arg

      Crystal::Parser::ArgExtras.new(nil, !!default_value, splat, !!double_splat)
    end

    def parse_arg_name(location, extra_assigns, allow_external_name)
      do_next_token = true
      found_string_literal = false
      invalid_internal_name = nil

      if allow_external_name && (@token.type == :IDENT || string_literal_start?)
        if @token.type == :IDENT
          if @token.keyword? && invalid_internal_name?(@token.value)
            invalid_internal_name = @token.dup
          end
          external_name = @token.type == :IDENT ? @token.value.to_s : ""
          next_token
        else
          external_name = parse_string_without_interpolation("external name")
          found_string_literal = true
        end
        found_space = @token.type == :SPACE || @token.type == :NEWLINE
        skip_space
        do_next_token = false
      end

      case @token.type
      when :IDENT
        if @token.keyword? && invalid_internal_name?(@token.value)
          raise "cannot use '#{@token}' as an argument name", @token
        end

        arg_name = @token.value.to_s
        if arg_name == external_name
          raise "when specified, external name must be different than internal name", @token
        end

        uses_arg = false
        do_next_token = true
      when :INSTANCE_VAR
        arg_name = @token.value.to_s[1..-1]
        if arg_name == external_name
          raise "when specified, external name must be different than internal name", @token
        end

        # If it's something like @select, we can't transform it to:
        #
        #     @select = select
        #
        # because if someone uses `to_s` later it will produce invalid code.
        # So we do something like:
        #
        # def method(select __arg0)
        #   @select = __arg0
        # end
        if !external_name && invalid_internal_name?(arg_name)
          arg_name, external_name = temp_arg_name, arg_name
        end

        ivar = Crystal::InstanceVar.new(@token.value.to_s).at(location)
        var = Crystal::Var.new(arg_name).at(location)
        assign = Crystal::Assign.new(ivar, var).at(location)
        if extra_assigns
          extra_assigns.push assign
        else
          raise "can't use @instance_variable here"
        end
        uses_arg = true
        do_next_token = true
      when :CLASS_VAR
        arg_name = @token.value.to_s[2..-1]
        if arg_name == external_name
          raise "when specified, external name must be different than internal name", @token
        end

        # Same case as :INSTANCE_VAR for things like @select
        if !external_name && invalid_internal_name?(arg_name)
          arg_name, external_name = temp_arg_name, arg_name
        end

        cvar = Crystal::ClassVar.new(@token.value.to_s).at(location)
        var = Crystal::Var.new(arg_name).at(location)
        assign = Crystal::Assign.new(cvar, var).at(location)
        if extra_assigns
          extra_assigns.push assign
        else
          raise "can't use @@class_var here"
        end
        uses_arg = true
        do_next_token = true
      else
        if external_name
          if found_string_literal
            raise "unexpected token: #{@token}, expected argument internal name"
          end
          if invalid_internal_name
            raise "cannot use '#{invalid_internal_name}' as an argument name", invalid_internal_name
          end
          arg_name = external_name
        else
          raise "unexpected token: #{@token}"
        end
      end

      if do_next_token
        next_token
        found_space = @token.type == :SPACE || @token.type == :NEWLINE
      end

      skip_space

      {arg_name, external_name, found_space, uses_arg}
    end
  end
end
